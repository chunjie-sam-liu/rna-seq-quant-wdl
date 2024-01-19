## Version 1.0

workflow QUANTIFICATION {
  Array[File] bams
  File ref_gtf
  String output_dir

  Int nthread = 10


  Int machine_mem_gb = 16
  Int disk_space_gb = 100
  Boolean use_ssd = false
  String docker_image = "chunjiesamliu/rna-seq-quant-wdl"
  String docker_version = "latest"

  scatter (bam in bams) {
    call CUFFLINKS {
      input:
        bam = bam,
        ref_gtf = ref_gtf,

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
      transcripts = CUFFLINKS.transcripts,
      genes = CUFFLINKS.genes,
      isoforms = CUFFLINKS.isoforms,
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

task CUFFLINKS {
  File bam
  File ref_gtf

  Int nthread = 10

  Int machine_mem_gb = 16
  Int disk_space_gb = 100
  Boolean use_ssd = false
  String docker_image = "chunjiesamliu/rna-seq-quant-wdl"
  String docker_version = "latest"


  String stripped_bam = basename(bam, ".bam")

  command {

    cufflinks \
      -p ${nthread} \
      -G ${ref_gtf} \
      -o ${stripped_bam} \
      ${bam}

    mv ${stripped_bam}/transcripts.gtf ${stripped_bam}/${stripped_bam}.transcripts.gtf
    mv ${stripped_bam}/genes.fpkm_tracking ${stripped_bam}/${stripped_bam}.genes.fpkm_tracking
    mv ${stripped_bam}/isoforms.fpkm_tracking ${stripped_bam}/${stripped_bam}.isoforms.fpkm_tracking
  }

  runtime {
    docker: "${docker_image}:${docker_version}"
    memory: "${machine_mem_gb} GB"
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
    cpu: nthread
  }

  output {
    File transcripts = "${stripped_bam}/${stripped_bam}.transcripts.gtf"
    File genes = "${stripped_bam}/${stripped_bam}.genes.fpkm_tracking"
    File isoforms = "${stripped_bam}/${stripped_bam}.isoforms.fpkm_tracking"
  }
}

task GATHREQUANT {
  Array[File] transcripts
  Array[File] genes
  Array[File] isoforms

  String output_dir

  Int nthread = 10

  Int machine_mem_gb = 16
  Int disk_space_gb = 100
  Boolean use_ssd = false
  String docker_image = "chunjiesamliu/rna-seq-quant-wdl"
  String docker_version = "latest"

  command {

    mkdir -p ${output_dir}

    for file in ${sep=" " transcripts}; do mv $file ${output_dir}; done
    for file in ${sep=" " genes}; do mv $file ${output_dir}; done
    for file in ${sep=" " isoforms}; do mv $file ${output_dir}; done

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