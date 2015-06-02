require "chef/aws/version"

module Chef
  module AWS
        def self.initialize
      @logger = Logger.new(STDOUT).tap do |log|
        log.formatter = proc do |severity, time, progname, msg|
          "#{progname} - #{msg}\n"
        end
        log.level = Logger::INFO
        log.progname = 'Chefspec'
      end

      @config = YAML.load_file( File.expand_path( "~/.aws/kitchen.yml") )
      @credentials = Aws::SharedCredentials.new(
        :profile_name => @config['driver']['shared_credentials_profile']
      )

      @rds = Aws::RDS::Client.new(
        region: @config['driver']['region'],
        credentials: @credentials
      )
    end

    def self.get_db_instance(id)
      instance = nil
      begin
        list = @rds.describe_db_instances(:db_instance_identifier => id)
        instance = list[:db_instances][0]
      rescue Aws::RDS::Errors::DBInstanceNotFound
        puts 'No hay instancia RDS para staging'
      end

      return instance
    end

    def self.create_db_instance(type)
      instance = get_db_instance("#{type.downcase}-staging")
      if instance.nil? then
        # hay que crear una nueva
        instance = @rds.create_db_instance(
          db_name: "db_staging",
          db_instance_identifier: "#{type.downcase}-staging",
          allocated_storage: 5,
          db_instance_class: "db.t2.micro",
          engine: type,
          master_username: "root",
          master_user_password: "testroot",
          vpc_security_group_ids: @config['driver']['db_security_group_ids'],
          db_subnet_group_name: @config['driver']['db_subnet_group'],
          # TODO version para PgSQL
          engine_version: (type.downcase == 'mysql' ? '5.6' : '9.3'),
          #character_set_name: 'UTF-8',
          publicly_accessible: false,
          multi_az: false,
          backup_retention_period: 0,
          tags: [
            { key: "Cliente", value: "Inetsys" },
            { key: "Concepto", value: "Testing" },
            { key: "Created-by", value: "Chef Repo staging" }
          ],
        )
        puts "Creating #{type.downcase}-staging RDS instance".green
        sleep 10
        instance = get_db_instance("#{type}-staging")
      end

      while instance[:db_instance_status] == 'creating' do
        sleep 5
        puts "Waiting for #{type.downcase}-staging to initialize (#{instance[:db_instance_status]}), retry in 5 seconds ...".blue
        instance = get_db_instance("#{type.downcase}-staging")
      end

      puts "RDS creation finished with status: #{instance[:db_instance_status]}".green

      return instance
    end

  end
end
