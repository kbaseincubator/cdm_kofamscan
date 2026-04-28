FROM quay.io/biocontainers/kofamscan:1.3.0--1

# Reference data (KEGG profile HMMs and ko_list) is mounted by CTS at /ref_data
ENV KOFAM_PROFILES /ref_data/profiles
ENV KOFAM_KO_LIST /ref_data/ko_list

# CTS requires an entrypoint
ENTRYPOINT ["exec_annotation"]
