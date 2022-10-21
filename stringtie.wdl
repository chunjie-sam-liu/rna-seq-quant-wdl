## Version 1.0

workflow QUANTIFICATION {
  Array[File] bams
  File ref_gtf
  Int read_length

  String out_dir

  Int nthread=1
  Int machine_mem_gb = 10
  Int disk_space_gb = 50
  Boolean use_ssd = false
  String sversion = "latest"

  scatter (bam in bams) {
    call STRINGTIE as STRINGTIE_A {
      input:
        bam = bam,
        ref_gtf = ref_gtf,
        read_length = read_length,

        annonovel = "annotated",

        nthread = nthread,
        machine_mem_gb = machine_mem_gb,
        disk_space_gb = disk_space_gb,
        use_ssd = use_ssd,
        sversion = sversion
    }
  }

  call PREPDE as PREPDE_A {
    input:
      dgeGtfs = STRINGTIE_A.dgeGtf,
      names = STRINGTIE_A.samplename,

      ref_gtf = ref_gtf,
      read_length = read_length,

      annonovel = "annotated",

      nthread = nthread,
      # machine_mem_gb = machine_mem_gb,
      # disk_space_gb = disk_space_gb,
      machine_mem_gb = 500,
      disk_space_gb = 1000,
      use_ssd = use_ssd,
      sversion = sversion
  }
  output {
    File gtfs = PREPDE_A.gtfs
    File samples = PREPDE_A.samples
    File sample_list = PREPDE_A.sample_list
    File gene_count = PREPDE_A.gene_count
    File transcript_count = PREPDE_A.transcript_count
  }




  meta {
    author: "Chun-Jie Liu"
    email : "chunjie.sam.liu@gmail.com"
    description: "WDL workflow on AnVIL for Stringtie developed in Dr. Yi Xing's lab"
  }

}

task STRINGTIE {
  File bam
  File ref_gtf
  Int read_length

  String annonovel

  Int nthread
  Int machine_mem_gb
  Int disk_space_gb
  Boolean use_ssd
  String sversion

  String name = basename(bam, ".Aligned.sortedByCoord.out.patched.md.bam")


  command {
    # echo "stringtie ${bam} -G ${ref_gtf} -o ${name}.${annonovel}.gtf -a 8 -p ${nthread}" > "${name}.${annonovel}.gtf"
    # echo "stringtie ${bam} -G ${ref_gtf} -o ${name}.${annonovel}_for_DGE.gtf -a 8 -p ${nthread}" > "${name}.${annonovel}_for_DGE.gtf"

    # formal code
    stringtie ${bam} -G ${ref_gtf} -o ${name}.${annonovel}.gtf -a 8 -p ${nthread}
    stringtie ${bam} -G ${ref_gtf} -o ${name}.${annonovel}_for_DGE.gtf -a 8 -e -p ${nthread}

  }

  output {
    String samplename = "${name}"
    File gtf = "${name}.${annonovel}.gtf"
    File dgeGtf = "${name}.${annonovel}_for_DGE.gtf"
  }

  runtime {
    docker: "chunjiesamliu/stringtie-nf:latest"
    memory: machine_mem_gb + " GB"
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
    cpu: nthread
  }
}

task PREPDE {
  Array[File] dgeGtfs
  Array[String] names

  File ref_gtf
  Int read_length

  String annonovel

  Int nthread
  Int machine_mem_gb
  Int disk_space_gb
  Boolean use_ssd
  String sversion

  command {
    echo ${sep="," names} | sed 's/,/\n/g' > samples.txt
    echo ${sep="," dgeGtfs} | sed 's/,/\n/g' > gtfs.txt
    paste -d ' ' samples.txt gtfs.txt > sample_lst.txt

    # echo "prepDE.py -i sample_lst.txt -l ${read_length} -g ${annonovel}_gene_count_matrix.csv -t ${annonovel}_transcript_count_matrix.csv" > ${annonovel}_gene_count_matrix.csv

    # echo "prepDE.py -i sample_lst.txt -l ${read_length} -g ${annonovel}_gene_count_matrix.csv -t ${annonovel}_transcript_count_matrix.csv" > ${annonovel}_transcript_count_matrix.csv


    # formal code
    prepDE.py -i sample_lst.txt -l ${read_length} -g ${annonovel}_gene_count_matrix.csv -t ${annonovel}_transcript_count_matrix.csv



  }
  output {
    File gtfs = "gtfs.txt"
    File samples = "samples.txt"
    File sample_list = "sample_lst.txt"
    File gene_count = "${annonovel}_gene_count_matrix.csv"
    File transcript_count = "${annonovel}_transcript_count_matrix.csv"
  }

  runtime {
    docker: "chunjiesamliu/stringtie-nf:latest"
    memory: machine_mem_gb + " GB"
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
    cpu: nthread
  }
}

# task STRINGTIEMERGE {
#   Array[File] gtfs


#   runtime {
#     docker: "chunjiesamliu/stringite-nf:" + sversion
#     memory: machine_mem_gb + " GB"
#     disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
#     cpu: nthread
#   }
# }
