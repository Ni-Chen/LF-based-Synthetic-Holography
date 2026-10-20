"""PyTorch implementation of the elemental-image Fourier hologram pipeline."""

import argparse
import math
from pathlib import Path

import torch
from PIL import Image


def read_rgb(path):
    with Image.open(path) as image:
        image = image.convert("RGB")
        width, height = image.size
        data = bytearray(image.tobytes())
    return torch.frombuffer(data, dtype=torch.uint8).reshape(height, width, 3).clone()


def write_image(path, image):
    image = image.detach().to(device="cpu", dtype=torch.uint8).contiguous()
    height, width = image.shape[:2]
    mode = "RGB" if image.ndim == 3 else "L"
    Image.frombytes(mode, (width, height), bytes(image.untyped_storage())).save(path)


def mosaic_to_light_field(image, element_size):
    height, width, channels = image.shape
    if height % element_size or width % element_size:
        raise ValueError(
            f"Image dimensions {width}x{height} must be divisible by "
            f"element size {element_size}."
        )
    view_y, view_x = height // element_size, width // element_size
    return (
        image.reshape(view_y, element_size, view_x, element_size, channels)
        .permute(0, 2, 1, 3, 4)
        .contiguous()
    )


def light_field_to_mosaic(light_field):
    view_y, view_x, pixel_y, pixel_x, channels = light_field.shape
    return (
        light_field.permute(0, 2, 1, 3, 4)
        .contiguous()
        .reshape(view_y * pixel_y, view_x * pixel_x, channels)
    )


def synthesize_elemental_image(input_dir, name, element_size):
    images = [
        read_rgb(input_dir / f"{name}_eleImg_{suffix}.jpg")
        for suffix in ("11", "12", "21", "22")
    ]
    light_fields = [mosaic_to_light_field(image, element_size) for image in images]
    if any(field.shape != light_fields[0].shape for field in light_fields[1:]):
        raise ValueError("The four input images must have matching dimensions.")

    top = torch.cat((light_fields[0], light_fields[1]), dim=3)
    bottom = torch.cat((light_fields[2], light_fields[3]), dim=3)
    mosaic = light_field_to_mosaic(torch.cat((top, bottom), dim=2))
    return mosaic


def threshold_elemental_image(image):
    image = image.to(torch.float32)
    image = torch.where(image < 20, 1.0, image)
    return torch.where(image > 150, 256.0, image)


def extract_sub_images(image, element_size):
    light_field = mosaic_to_light_field(image, element_size)
    sub_images = light_field.permute(2, 3, 0, 1, 4)
    weights = image.new_tensor((0.299, 0.587, 0.114), dtype=torch.float32)
    grayscale = (sub_images.to(torch.float32) * weights).sum(dim=-1)
    return grayscale, light_field.shape[:2]


def generate_fourier_cgh(
    projections,
    full_view_shape,
    lens_focal_length,
    lens_array_pitch,
    wavelength,
    projection_pixel,
    sample_division,
    device,
    row_chunk_size,
):
    pixel_y, pixel_x, projection_y, projection_x = projections.shape
    full_view_y, full_view_x = full_view_shape
    delta_s = lens_array_pitch / full_view_x
    delta_t = lens_array_pitch / full_view_y

    half_x, half_y = projection_x // 2, projection_y // 2
    max_s, min_s = half_x * delta_s, -(projection_x - half_x - 1) * delta_s
    max_t, min_t = half_y * delta_t, -(projection_y - half_y - 1) * delta_t

    num_s = round((max_s - min_s) / (delta_s / sample_division)) + 1
    num_t = round((max_t - min_t) / (delta_t / sample_division)) + 1
    s_values = min_s + torch.arange(num_s, dtype=torch.float64) * (
        delta_s / sample_division
    )
    t_values = min_t + torch.arange(num_t, dtype=torch.float64) * (
        delta_t / sample_division
    )
    s_indices = torch.arange(num_s) // sample_division
    t_indices = torch.arange(num_t) // sample_division

    source_x = (
        torch.arange(pixel_x, dtype=torch.float64) - pixel_x / 2
    ) * projection_pixel
    source_y = (
        torch.arange(pixel_y, dtype=torch.float64) - pixel_y / 2
    ) * projection_pixel
    x_grid = source_x.reshape(1, 1, 1, pixel_x)
    y_grid = source_y.reshape(1, 1, pixel_y, 1)
    s_grid = s_values.reshape(1, num_s, 1, 1)
    b = -2 / (wavelength * lens_focal_length)

    projections = projections.to(device=device, dtype=torch.float64)
    cgh = torch.empty((num_t, num_s), dtype=torch.complex128, device=device)
    for start in range(0, num_t, row_chunk_size):
        end = min(start + row_chunk_size, num_t)
        t_grid = t_values[start:end].reshape(-1, 1, 1, 1)
        selected = projections.index_select(2, t_indices[start:end]).index_select(
            3, s_indices
        )
        selected = selected.permute(2, 3, 0, 1)
        phase = 2 * math.pi * b * (x_grid * s_grid + y_grid * t_grid)
        field = selected * torch.exp(-1j * phase)
        cgh[start:end] = field.sum(dim=(-2, -1))

    return cgh, s_values.to(device), t_values.to(device), delta_s, delta_t


def normalized_uint8(tensor):
    tensor = tensor.real if tensor.is_complex() else tensor
    tensor = tensor.to(torch.float32)
    minimum, maximum = tensor.min(), tensor.max()
    if maximum == minimum:
        return torch.zeros_like(tensor, dtype=torch.uint8)
    return ((tensor - minimum) / (maximum - minimum) * 255).round().to(torch.uint8)


def reconstruct_depths(
    cgh,
    s_values,
    t_values,
    delta_s,
    sample_division,
    lens_focal_length,
    reconstruction_wavelength,
    depth_offsets,
    output_dir,
    name,
):
    delta_u = delta_v = 10e-6
    magnification = delta_u / (delta_s / sample_division)
    lens_f = -magnification * lens_focal_length / 2
    u = (s_values * magnification).reshape(1, -1)
    v = (t_values * magnification).reshape(-1, 1)

    for depth_offset in depth_offsets:
        propagation_distance = lens_f + depth_offset
        phase = (
            math.pi
            / reconstruction_wavelength
            / lens_f
            * (1 - propagation_distance / lens_f)
            * (u.square() + v.square())
        )
        reconstructed = torch.fft.fftshift(
            torch.fft.fft2(cgh * torch.exp(1j * phase))
        )
        suffix = f"{depth_offset * 1000:g}mm"
        write_image(
            output_dir / f"{name}_reconstruction_{suffix}.png",
            normalized_uint8(reconstructed.abs()),
        )


def main():
    script_dir = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(
        description="Synthesize elemental images and Fourier holograms with PyTorch."
    )
    parser.add_argument("--name", default="foot", help="Input/output image prefix.")
    parser.add_argument("--input-dir", type=Path, default=script_dir / "output")
    parser.add_argument("--output-dir", type=Path, default=script_dir / "output")
    parser.add_argument("--element-size", type=int, default=50)
    parser.add_argument("--lens-focal-length", type=float, default=3.3e-3)
    parser.add_argument("--lens-array-pitch", type=float, default=1e-3)
    parser.add_argument("--wavelength", type=float, default=300e-6)
    parser.add_argument("--reconstruction-wavelength", type=float, default=300e-6)
    parser.add_argument("--projection-pixel", type=float, default=0.5e-3)
    parser.add_argument("--sample-division", type=int, default=4)
    parser.add_argument("--invalid-left", type=int, default=3)
    parser.add_argument("--invalid-right", type=int, default=3)
    parser.add_argument("--invalid-up", type=int, default=3)
    parser.add_argument("--invalid-down", type=int, default=3)
    parser.add_argument("--depth-start", type=float, default=45e-3)
    parser.add_argument("--depth-stop", type=float, default=80e-3)
    parser.add_argument("--depth-step", type=float, default=5e-3)
    parser.add_argument("--device", default="auto")
    parser.add_argument("--row-chunk-size", type=int, default=2)
    args = parser.parse_args()

    if args.element_size <= 0 or args.sample_division <= 0 or args.row_chunk_size <= 0:
        parser.error("element-size, sample-division, and row-chunk-size must be positive.")
    for value, label in (
        (args.lens_focal_length, "lens-focal-length"),
        (args.lens_array_pitch, "lens-array-pitch"),
        (args.wavelength, "wavelength"),
        (args.reconstruction_wavelength, "reconstruction-wavelength"),
        (args.projection_pixel, "projection-pixel"),
        (args.depth_step, "depth-step"),
    ):
        if value <= 0:
            parser.error(f"{label} must be positive.")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    mosaic = synthesize_elemental_image(args.input_dir, args.name, args.element_size)
    write_image(args.output_dir / f"{args.name}_eleImg_syn.jpg", mosaic)

    # Match the MATLAB pipeline's JPEG round-trip before thresholding and extraction.
    mosaic = read_rgb(args.output_dir / f"{args.name}_eleImg_syn.jpg")
    processed = threshold_elemental_image(mosaic)
    write_image(
        args.output_dir / f"{args.name}_eleImg.jpg",
        processed.to(torch.uint8),
    )
    sub_images, full_view_shape = extract_sub_images(processed, args.element_size)
    sub_mosaic = sub_images.permute(2, 0, 3, 1).contiguous()
    sub_mosaic = sub_mosaic.reshape(
        sub_images.shape[2] * sub_images.shape[0],
        sub_images.shape[3] * sub_images.shape[1],
    )
    write_image(
        args.output_dir / f"{args.name}_subImg.jpg",
        normalized_uint8(sub_mosaic),
    )

    _, _, view_y, view_x = sub_images.shape
    y_start, y_end = args.invalid_up, view_y - args.invalid_down
    x_start, x_end = args.invalid_left, view_x - args.invalid_right
    if y_start >= y_end or x_start >= x_end:
        parser.error("Invalid-view clipping removes all projection views.")
    projections = sub_images[:, :, y_start:y_end, x_start:x_end]
    if args.device == "auto":
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    else:
        device = torch.device(args.device)

    cgh, s_values, t_values, delta_s, delta_t = generate_fourier_cgh(
        projections,
        full_view_shape,
        args.lens_focal_length,
        args.lens_array_pitch,
        args.wavelength,
        args.projection_pixel,
        args.sample_division,
        device,
        args.row_chunk_size,
    )
    torch.save(
        {
            "CGH": cgh.cpu(),
            "deltaS": delta_s / args.sample_division,
            "deltaT": delta_t / args.sample_division,
        },
        args.output_dir / f"{args.name}_CGH_DATA.pt",
    )
    write_image(
        args.output_dir / f"{args.name}_holo_real.png",
        normalized_uint8(cgh.real),
    )
    write_image(
        args.output_dir / f"{args.name}_holo_imag.png",
        normalized_uint8(cgh.imag),
    )

    depth_count = math.floor(
        (args.depth_stop - args.depth_start) / args.depth_step + 1e-9
    )
    depths = [
        args.depth_start + index * args.depth_step
        for index in range(depth_count + 1)
    ]
    reconstruct_depths(
        cgh,
        s_values,
        t_values,
        delta_s,
        args.sample_division,
        args.lens_focal_length,
        args.reconstruction_wavelength,
        depths,
        args.output_dir,
        args.name,
    )
    print(f"Saved hologram outputs to {args.output_dir}")


if __name__ == "__main__":
    main()
