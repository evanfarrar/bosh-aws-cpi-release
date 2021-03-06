module Bosh::AwsCloud
  class StemcellCloudProps
    attr_reader :ami, :encrypted, :kms_key_arn
    attr_reader :disk, :architecture, :virtualization_type, :root_device_name, :kernel_id

    # @param [Hash] cloud_properties
    # @param [Bosh::AwsCloud::Config] global_config
    def initialize(cloud_properties, global_config)
      @global_config = global_config
      @cloud_properties = cloud_properties.merge(@global_config.aws.stemcell)

      @ami = @cloud_properties['ami']

      @encrypted = @global_config.aws.encrypted
      @encrypted = !!@cloud_properties['encrypted'] if @cloud_properties.key?('encrypted')

      @kms_key_arn = @global_config.aws.kms_key_arn
      @kms_key_arn = @cloud_properties['kms_key_arn'] if @cloud_properties.key?('kms_key_arn')

      @name = @cloud_properties['name']
      @version = @cloud_properties['version']

      @disk = @cloud_properties['disk'] || DEFAULT_DISK_SIZE
      @architecture = @cloud_properties['architecture']
      @virtualization_type = @cloud_properties['virtualization_type'] || 'hvm'
      @root_device_name = @cloud_properties['root_device_name']
      @kernel_id = @cloud_properties['kernel_id']
    end

    # old stemcells doesn't have name & version
    def old?
      @name && @version
    end

    def formatted_name
      "#{@name} #{@version}"
    end

    def paravirtual?
      virtualization_type == PARAVIRTUAL
    end

    def is_light?
      !ami.nil? && !ami.empty?
    end

    def ami_ids
      ami.values
    end

    def region_ami
      ami[@global_config.aws.region]
    end

    private

    DEFAULT_DISK_SIZE = 2048
    PARAVIRTUAL = 'paravirtual'.freeze

  end

  class DiskCloudProps
    attr_reader :type, :iops, :encrypted, :kms_key_arn

    # @param [Hash] cloud_properties
    # @param [Bosh::AwsCloud::Config] global_config
    def initialize(cloud_properties, global_config)
      @type = cloud_properties['type']
      @iops = cloud_properties['iops']

      @encrypted = global_config.aws.encrypted
      @encrypted = !!cloud_properties['encrypted'] if cloud_properties.key?('encrypted')

      @kms_key_arn = global_config.aws.kms_key_arn
      @kms_key_arn = cloud_properties['kms_key_arn'] if cloud_properties.key?('kms_key_arn')
    end
  end

  class VMCloudProps
    attr_reader :lb_target_groups, :elbs

    # @param [Hash] cloud_properties
    # @param [Bosh::AwsCloud::Config] global_config
    def initialize(cloud_properties, global_config)
      @cloud_properties = cloud_properties.dup

      @elbs = cloud_properties['elbs'] || []
      @lb_target_groups = cloud_properties['lb_target_groups'] || []

      encrypted = global_config.aws.encrypted
      if encrypted
        if @cloud_properties['ephemeral_disk']
          if @cloud_properties['ephemeral_disk'].key?('encrypted')
            encrypted = !!@cloud_properties['ephemeral_disk']['encrypted']
          end
          @cloud_properties['ephemeral_disk']['encrypted'] = encrypted
        else
          @cloud_properties['ephemeral_disk'] = {
            'encrypted' => encrypted
          }
        end
      end
    end

    def to_h
      @cloud_properties
    end
  end

  class PropsFactory
    def initialize(config)
      @config = config
    end

    def stemcell_props(stemcell_properties)
      Bosh::AwsCloud::StemcellCloudProps.new(stemcell_properties, @config)
    end

    def disk_props(disk_properties)
      Bosh::AwsCloud::DiskCloudProps.new(disk_properties, @config)
    end

    def vm_props(vm_properties)
      Bosh::AwsCloud::VMCloudProps.new(vm_properties, @config)
    end
  end
end