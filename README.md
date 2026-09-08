# *Brassica* conservation gap analysis

This repository hosts the interactive maps and supporting website for Taylor et al. "Integrating genebank and biodiversity database indicators to optimise conservation of *Brassica* crop wild relatives" (manuscript reference NCOMMS-26-013746A).

The site is published with GitHub Pages at <https://candytaylor.github.io/Brassica-conservation-gap-analysis/>.

Please refer to the [GapAnalysis repository](https://github.com/dcarver1/GapAnalysis/tree/master) for more information about the GapAnalysis R package used in this study.

---

## Organisation of repository

### Published website (Jekyll)
- `index.md` : landing page, including the species grid linking to each taxon
- `Maps/` : one Markdown page per taxon (21 files), each embedding that taxon's interactive map
- `_layouts/` : page templates (`default.html`, `species.html`)
- `_config.yml` : Jekyll configuration, including the `baseurl` required for project-site hosting
- `assets/` : stylesheets, images, and the generated Leaflet maps in `assets/maps/`
- `_scripts/generate_species_pages.sh` : regenerates the `Maps/*.md` stubs from the map files present in `assets/maps/`

### Archived analysis code
- `original/DistributionModels/BinarySDM.R` : converts ecological niche models to binary format for the conservation gap analysis
- `original/Maps/InteractiveMap.R` : generates the interactive Leaflet maps
- `original/Website/` : the earlier R Markdown version of the website, superseded by the Jekyll site above

---

## Rebuilding the site

1. Place the generated Leaflet map for each taxon in `assets/maps/` as `Brassica_<epithet>.html`.
2. Run `bash _scripts/generate_species_pages.sh` to regenerate the per-taxon pages in `Maps/`.
3. Add or update the corresponding link in the species grid in `index.md`.
4. Build locally with `bundle exec jekyll serve`, or push to `main` to publish via GitHub Pages.
