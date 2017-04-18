SELECT
	gbs.flowcell,
	gbs.lane,
	barcodes.barcode,
	dna.sample_name,
	dna.plate_id,
	substring(dna.well_A01, 1, 1),
	substring(dna.well_A01, 2, 2),
	dna.well_A01,
	gbs.project,
	gbs.enzyme,
	dna.tissue_id,
	dna.sample_id,
	gbs.gbs_id,
	gbs.gbs_name,
	dna.plate_name,
	plant.plant_name,
	plant.source_seed_id,
	dna.external_id,
	dna.dna_person,
	dna.notes,
	plant.notes,
	gbs.plexing,
	dna.line_num,
	barcodes.`set`
FROM
	dna
LEFT JOIN gbs ON gbs.dna_id = dna.plate_id
LEFT JOIN plant ON dna.tissue_id = plant.plant_id
INNER JOIN barcodes ON dna.well_A01 = barcodes.well_A01
AND gbs.plexing LIKE barcodes.`set`
WHERE
	gbs.project LIKE "tauschiiRIL"
ORDER BY
	gbs.gbs_id,
	dna.well_01A ASC
