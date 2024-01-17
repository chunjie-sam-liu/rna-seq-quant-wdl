## Version 1.0

workflow QUANTIFICATION {
  Array[File] bams
  String salmon_index
  String output_dir

  Int nthread = 10


  Int machine_mem_gb = 16
  Int disk_space_gb = 100
  Boolean use_ssd = false
  String docker_image = "chunjiesamliu/rna-seq-quant-wdl"
  String docker_version = "latest"

  scatter (bam in bams) {
    call SALMON {
      input:
        bam = bam,
        salmon_index = salmon_index,

        nthread = nthread,
        machine_mem_gb = machine_mem_gb,
        disk_space_gb = disk_space_gb,
        use_ssd = use_ssd,
        docker_image = docker_image,
        docker_version = docker_version
    }
  }
  call GATHREQUANT {
    input:
      transcripts = SALMON.sf,
      output_dir = output_dir,
      nthread = nthread,
      machine_mem_gb = machine_mem_gb,
      disk_space_gb = disk_space_gb,
      use_ssd = use_ssd,
      docker_image = docker_image,
      docker_version = docker_version
  }

  output {
    File output_result = GATHREQUANT.output_result
  }

    meta {
    author: "Chun-Jie Liu"
    email : "chunjie.sam.liu@gmail.com"
    description: "WDL workflow on AnVIL for short RNA-seq quantification developed in Dr. Yi Xing's lab"
  }

}

task SALMON {
  File bam
  String salmon_index

  Int nthread = 10

  Int machine_mem_gb = 16
  Int disk_space_gb = 100
  Boolean use_ssd = false
  String docker_image = "chunjiesamliu/rna-seq-quant-wdl"
  String docker_version = "latest"


  String stripped_bam = basename(bam, ".bam")

  command {
    samtools bam2fq -@ ${nthread} ${bam} > ${stripped_bam}.fastq
    salmon quant \
      -i ${salmon_index} \
      -l A \
      -r ${stripped_bam}.fastq \
      -p ${nthread} \
      -o ${stripped_bam}

    mv ${stripped_bam}/quant.sf ${stripped_bam}/${stripped_bam}.quant.sf

  }

  runtime {
    docker: "${docker_image}:${docker_version}"
    memory: "${machine_mem_gb} GB"
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
    cpu: nthread
  }

  output {
    File sf = "${stripped_bam}/${stripped_bam}.quant.sf"
  }
}

task GATHREQUANT {
  Array[File] transcripts

  String output_dir

  Int nthread = 10

  Int machine_mem_gb = 16
  Int disk_space_gb = 100
  Boolean use_ssd = false
  String docker_image = "chunjiesamliu/rna-seq-quant-wdl"
  String docker_version = "latest"

  command {

    echo "Gathering results"
    mkdir -p output_dir
    for file in ${sep=" " transcripts}; do cp $file ${output_dir}; done

    tar -czvf ${output_dir}.tar.gz ${output_dir}

  }

  runtime {
    docker: "${docker_image}:${docker_version}"
    memory: "${machine_mem_gb} GB"
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
    cpu: nthread
  }

  output {
    File output_result = "${output_dir}.tar.gz"
  }
}