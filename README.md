# Integral imaging based synthetic holography

| ![ii_ortho_holo](notebook/img/ii_ortho_holo.png)             |
| ------------------------------------------------------------ |
| Schematic of hologram synthesize from orthographic view images |



## Resolution enhancement

A PyTorch version of the elemental-image synthesis and Fourier hologram pipeline
is available in [`code/LFFREncode.py`](code/LFFREncode.py). It expects four
preprocessed images named `<name>_eleImg_11.jpg`, `_12.jpg`, `_21.jpg`, and
`_22.jpg` in the input directory. For example, the repository's existing `foot`
intermediate images can be processed from the repository root with:

```bash
pip install "torch>=2.7.1" "Pillow>=12.3.0"
python code/LFFREncode.py
```

The script writes the synthesized elemental image, sub-image mosaic, complex
hologram data (`.pt`), real/imaginary hologram previews, and depth
reconstructions to `code/output/`. Use `--help` to see options for input paths,
optical parameters, view clipping, and compute device. Defaults match the
`foot` MATLAB parameter file. The MATLAB preprocessing scripts remain necessary
when starting from the original captured photographs rather than the
preprocessed intermediate images.


A set of captured elemental images

| ![eleImg_11](notebook/img/eleImg_11.JPG) | ![eleImg_12](notebook/img/eleImg_12.JPG) |
| ---------------------------------------: | :--------------------------------------- |
| ![eleImg_21](notebook/img/eleImg_21.JPG) | ![eleImg_22](notebook/img/eleImg_22.JPG) |



Synthezed elemental image
<img src="./code/data/girl/eleImg_syn.jpg" alt="" width="400"/> -->





## References

- Min Wan, Inbarasan Muniraj, Ra’ed Malallah, Ni Chen, John J. Healy, James P. Ryle, and John T. Sheridan, “Orthographic projection images based photon counted integral Fourier holography”, Applied Optics, 58(10):2656-2661, Mar. 2019. 
- Ni Chen, Zhenbo Ren, and Edmund Y. Lam, “High resolution Fourier hologram synthesis from photographic images through computing the light field”, Applied Optics, 55(7):1751–1756, Mar. 2016. 
- Ni Chen, Jiwoon Yeom, Jae-Hyun Jung, Jae-Hyeung Park, and Byoungho Lee, “Resolution comparison between integral-imaging-based hologram synthesis methods using rectangular and hexagonal lens arrays”, Optics Express, 19(27):26917–26927, Dec. 2011.
- Ni Chen, Jae-Hyeung Park, and Nam Kim, “Parameter analysis of integral Fourier hologram and its resolution enhancement”, Optics Express, 18(3):2152–2167, Jan. 2010. 