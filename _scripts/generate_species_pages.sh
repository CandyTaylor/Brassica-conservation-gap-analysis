for file in assets/maps/Brassica_*.html; do
    # 1. Get the filename without path or extension
    name=$(basename "$file" .html)
    
    # 2. Clean up name for the title (replace _ with space)
    display_name=$(echo $name | sed 's/_/ /g')

    # 3. Create the .md file with Front Matter AND Markdown content
    cat <<EOF > Maps/${name}.md
---
layout: species
taxon_name: "$display_name"
map_asset: "/assets/maps/${name}.html"
---

## Information about map

The taxon-specific interactive map illustrates:

### **Predicted distributions**
You may toggle between the following two distribution models by selecting the model of choice in the upper right corner of the map:

- **Original ecological niche model distribution**: Created using occurrence records, WorldClim, and SoilGrids data. Habitat suitability is presented on a yellow (0.0) to red (1.0) colour scale.
- **Binary thresholded distribution model**: Used for conservation gap analysis, thresholded using the mean habitat suitability score for the taxon.

### **Occurrence records**
- **H (Observation)**: Reference occurrence records obtained from GBIF and iDigBio. Blue markers.
- **H (Historic accession)**: Historic germplasm accessions from Genesys. Black markers.
- **G (Active accession)**: Actively maintained accessions from Genesys. Green markers.
- **G buffer**: A 50 Km radial buffer area surrounding each germplasm record (G).

### **Conservation gaps**
- ***Ex situ* ecoregion gaps**: Ecoregions lacking representation by germplasm (pink shading).
- ***In situ* ecoregion gaps**: Ecoregions lacking protected areas (purple shading).

EOF
done
