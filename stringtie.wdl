## Version 1.0

workflow QUANTIFICATION {
  Array[File] bams
  File ref_gtf
  Int readLength

  String out_dir

  Int nthread=1
  Int machine_mem_gb = 4
  Int disk_space_gb = 50
  Boolean use_ssd = false
  String sversion = "latest"

  scatter (i range(length(bams))) {
    call STRINGTIE as STRINGTIE_A {
      input:
        indexedBam = bams[i]
        annonovel = "annotated"
        ref_gtf = ref_gtf

        machine_mem_gb = machine_mem_gb
        disk_space_gb = disk_space_gb
        use_ssd = use_ssd
        sversion = sversion
    }
  }

  call PREPDE as PREPDE_A {
    input:
      gtfs = STRINGTIE_A.dgeGtf

      machine_mem_gb = machine_mem_gb
      disk_space_gb = disk_space_gb
      use_ssd = use_ssd
      sversion = sversion
  }

  call STRINGTIEMERGE {
    input:
      gtfs = STRINGTIE_A.gtf
  }

  # scatter (i range(length(bams))) {
  #   call STRINGTIE as STRINGTIE_N
  # }

  # call PREPDE as PREPDE_N


  meta {
    author: "Chun-Jie Liu"
    email : "chunjie.sam.liu@gmail.com"
    description: "WDL workflow on AnVIL for Stringtie developed in Dr. Yi Xing's lab"
  }

}

task STRINGTIE {
  File indexedBam
  String annonovel
  File ref_gtf

  Int nthread
  Int machine_mem_gb
  Int disk_space_gb
  Boolean use_ssd
  String sversion

  command {

    name=${indexedBam%.bam}
    stringtie ${indexedBam} -G ${ref_gtf} -o ${name}.${annonovel}.gtf -a 8 -p ${nthread}
    stringtie ${indexedBam} -G ${ref_gtf} -o ${name}.${annonovel}_for_DGE.gtf -a 8 -p ${nthread}
  }

  output {
    File gtf = ${name}.${annonovel}.gtf
    File dgeGtf = ${name}.${annonovel}_for_DGE.gtf
  }

  runtime {
    docker: "chunjiesamliu/stringite-nf:latest"
    memory: machine_mem_gb + " GB"
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
    cpu: nthread
  }
}

task PREPDE {
  Array[File] gtfs
  String annonovel

  Int readLength

  Int nthread
  Int machine_mem_gb
  Int disk_space_gb
  Boolean use_ssd
  String sversion

  command {
    # echo "${gtf.join("\n").toString().replace(".${annonovel}_for_DGE.gtf", "")}" > samples.txt
    for i
    # echo "${gtf.join("\n")}" > gtfs.txt
    for f in ${sep=" " gtfs}; do echo ${f%_for_DGE.gtf};done
    paste -d ' ' samples.txt gtfs.txt > sample_lst.txt
    prepDE.py \
      -i sample_lst.txt \
      -l ${readLength} \
      -g ${annonovel}_gene_count_matrix.csv \
      -t ${annonovel}_transcript_count_matrix.csv
  }

  runtime {
    docker: "chunjiesamliu/stringite-nf:" + sversion
    memory: machine_mem_gb + " GB"
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
    cpu: nthread
  }
}

task STRINGTIEMERGE {
  Array[File] gtfs


  runtime {
    docker: "chunjiesamliu/stringite-nf:" + sversion
    memory: machine_mem_gb + " GB"
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
    cpu: nthread
  }
}
