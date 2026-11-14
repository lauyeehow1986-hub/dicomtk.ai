# Build curated LOINC-RSNA Radiology Playbook & RadLex protocol reference table
# Run via Rscript data-raw/build_radlex_playbook.R

rows <- list(
  # CT
  c("RPID16", "CT Head WO contrast", "CT Head WO", "CT", "HEAD", "RID6434", "FALSE", "head brain noncontrast ncct stroke wo"),
  c("RPID17", "CT Head W contrast IV", "CT Head W", "CT", "HEAD", "RID6434", "TRUE", "head brain contrast cect iv"),
  c("RPID18", "CT Head Angiography W contrast IV", "CTA Head", "CT", "HEAD", "RID6434", "TRUE", "cta head circle of willis angio"),
  c("RPID22", "CT Cervical Spine WO contrast", "CT C-Spine WO", "CT", "CSPINE", "RID7749", "FALSE", "cspine cervical spine neck trauma"),
  c("RPID29", "CT Chest WO contrast", "CT Chest WO", "CT", "CHEST", "RID1243", "FALSE", "chest thorax lung hrct ldct screening wo"),
  c("RPID30", "CT Chest W contrast IV", "CT Chest W", "CT", "CHEST", "RID1243", "TRUE", "chest thorax contrast cect"),
  c("RPID32", "CT Chest Pulmonary Arteries Angiography W contrast IV", "CTPA Chest", "CT", "CHEST", "RID1243", "TRUE", "ctpa pe pulmonary embolism angio"),
  c("RPID41", "CT Abdomen WO contrast", "CT Abd WO", "CT", "ABDOMEN", "RID56", "FALSE", "abdomen kidney stone kub noncontrast"),
  c("RPID42", "CT Abdomen W contrast IV", "CT Abd W", "CT", "ABDOMEN", "RID56", "TRUE", "abdomen liver portal venous multiphasic"),
  c("RPID45", "CT Abdomen and Pelvis WO contrast", "CT Abd/Pelvis WO", "CT", "ABDOMEN_PELVIS", "RID56", "FALSE", "abdomen pelvis ap wo noncontrast"),
  c("RPID46", "CT Abdomen and Pelvis W contrast IV", "CT Abd/Pelvis W", "CT", "ABDOMEN_PELVIS", "RID56", "TRUE", "abdomen pelvis ap contrast portal"),
  c("RPID48", "CT Chest Abdomen and Pelvis W contrast IV", "CT CAP W", "CT", "CHEST_ABDOMEN_PELVIS", "RID39475", "TRUE", "cap staging chest abdomen pelvis oncology"),
  c("RPID51", "CT Coronary Angiography W contrast IV", "CCTA Heart", "CT", "HEART", "RID1385", "TRUE", "ccta coronary calcium cardiac heart"),
  c("RPID55", "CT Lumbar Spine WO contrast", "CT L-Spine WO", "CT", "LSPINE", "RID7766", "FALSE", "lspine lumbar spine back"),
  # MR
  c("RPID101", "MR Brain WO contrast", "MR Brain WO", "MR", "HEAD", "RID6434", "FALSE", "brain head t1 t2 flair dwi adc wo"),
  c("RPID102", "MR Brain WO and W contrast IV", "MR Brain WO/W", "MR", "HEAD", "RID6434", "TRUE", "brain head gad post contrast t1c tumor"),
  c("RPID105", "MR Brain Angiography WO contrast", "MRA Brain TOF", "MR", "HEAD", "RID6434", "FALSE", "mra tof circle of willis angio"),
  c("RPID110", "MR Cervical Spine WO contrast", "MR C-Spine WO", "MR", "CSPINE", "RID7749", "FALSE", "cspine cervical cord stir"),
  c("RPID112", "MR Lumbar Spine WO contrast", "MR L-Spine WO", "MR", "LSPINE", "RID7766", "FALSE", "lspine lumbar disc sciatica"),
  c("RPID118", "MR Cardiac Function and Viability WO and W contrast IV", "Cardiac MRI", "MR", "HEART", "RID1385", "TRUE", "cardiac cine lge heart viability"),
  c("RPID121", "MR Liver WO and W contrast IV", "MR Liver", "MR", "ABDOMEN", "RID58", "TRUE", "liver eovist primovist hepatobiliary mri"),
  c("RPID124", "MR Prostate Multiparametric WO and W contrast IV", "mpMRI Prostate", "MR", "PELVIS", "RID343", "TRUE", "prostate pirads mpmri dce"),
  c("RPID128", "MR Knee WO contrast", "MR Knee WO", "MR", "KNEE", "RID2743", "FALSE", "knee acl meniscus pd fs"),
  c("RPID130", "MR Shoulder WO contrast", "MR Shoulder WO", "MR", "SHOULDER", "RID1853", "FALSE", "shoulder rotator cuff labrum"),
  c("RPID135", "MR Breast Bilateral WO and W contrast IV", "MR Breast", "MR", "BREAST", "RID29896", "TRUE", "breast bilateral screening dynamic"),
  # PET / NM
  c("RPID201", "PET CT Whole Body FDG-18F", "PET/CT WB FDG", "PT", "WHOLEBODY", "RID39475", "TRUE", "pet ct fdg whole body wb oncology"),
  c("RPID202", "PET CT Skull Base to Mid-Thigh FDG-18F", "PET/CT Torso FDG", "PT", "CHEST_ABDOMEN_PELVIS", "RID39475", "TRUE", "pet ct torso skull base mid thigh fdg"),
  c("RPID205", "PET CT Prostate PSMA-68Ga", "PET/CT PSMA", "PT", "WHOLEBODY", "RID343", "TRUE", "pet psma ga68 prostate"),
  c("RPID208", "PET MR Brain FDG-18F", "PET/MR Brain", "PT", "HEAD", "RID6434", "TRUE", "pet mr brain dementia epilepsy"),
  c("RPID210", "NM Bone Whole Body Scintigraphy", "NM Bone Scan", "NM", "WHOLEBODY", "RID39475", "TRUE", "bone scan mdp tc99m scintigraphy"),
  # DX / CR / Radiography
  c("RPID301", "XR Chest 2 Views PA and Lateral", "CXR PA/Lat", "DX", "CHEST", "RID1243", "FALSE", "chest xray cxr pa lateral"),
  c("RPID302", "XR Chest Single View AP Portable", "CXR Portable AP", "DX", "CHEST", "RID1243", "FALSE", "chest portable ap icu cxr"),
  c("RPID305", "XR Abdomen Supine KUB", "AXR KUB", "DX", "ABDOMEN", "RID56", "FALSE", "abdomen kub supine xray"),
  c("RPID310", "XR Knee AP and Lateral", "XR Knee", "DX", "KNEE", "RID2743", "FALSE", "knee xray ap lateral"),
  c("RPID312", "XR Pelvis AP", "XR Pelvis", "DX", "PELVIS", "RID2507", "FALSE", "pelvis hip ap xray"),
  c("RPID315", "XR Hand 3 Views", "XR Hand", "DX", "HAND", "RID2318", "FALSE", "hand bone age xray"),
  # MG / Mammography & DBT
  c("RPID401", "MG Breast Screening Bilateral", "Screening Mammo", "MG", "BREAST", "RID29896", "FALSE", "mammogram screening cc mlo bilateral"),
  c("RPID402", "MG Breast Diagnostic Bilateral", "Diagnostic Mammo", "MG", "BREAST", "RID29896", "FALSE", "mammogram diagnostic spot compression"),
  c("RPID405", "MG Breast Digital Tomosynthesis Bilateral", "DBT Mammo", "MG", "BREAST", "RID29896", "FALSE", "tomosynthesis dbt 3d mammogram"),
  # US / Ultrasound
  c("RPID501", "US Abdomen Complete", "US Abdomen", "US", "ABDOMEN", "RID56", "FALSE", "ultrasound abdomen liver gallbladder"),
  c("RPID502", "US Pelvis Transabdominal", "US Pelvis", "US", "PELVIS", "RID2507", "FALSE", "ultrasound pelvis bladder"),
  c("RPID505", "US Thyroid and Neck", "US Thyroid", "US", "NECK", "RID7488", "FALSE", "ultrasound thyroid neck parathyroid"),
  c("RPID508", "US Lower Extremity Venous Doppler", "US DVT Doppler", "US", "EXTREMITY", "RID2660", "FALSE", "doppler dvt venous leg duplex"),
  c("RPID510", "US Echocardiography Transthoracic", "TTE Echo", "US", "HEART", "RID1385", "FALSE", "echocardiogram tte cardiac echo"),
  # XA / Fluoroscopy
  c("RPID601", "XA Coronary Angiography", "Cath Angio", "XA", "HEART", "RID1385", "TRUE", "coronary angiogram pci cath xa"),
  c("RPID605", "XA Cerebral Angiography", "DSA Cerebral", "XA", "HEAD", "RID6434", "TRUE", "dsa cerebral angiogram stroke")
)

mat <- do.call(rbind, rows)
radlex_playbook <- tibble::tibble(
  rpid = mat[, 1L],
  long_common_name = mat[, 2L],
  short_name = mat[, 3L],
  modality = mat[, 4L],
  body_region = mat[, 5L],
  radlex_id = mat[, 6L],
  contrast = as.logical(mat[, 7L]),
  keywords = mat[, 8L]
)

dir.create("C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.ai/data", recursive = TRUE, showWarnings = FALSE)
save(
  radlex_playbook,
  file = "C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.ai/data/radlex_playbook.rda",
  compress = "bzip2"
)
cat("Saved radlex_playbook with", nrow(radlex_playbook), "rows.\n")
