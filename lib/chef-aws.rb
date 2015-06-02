require "chef-aws/version"
require "aws-sdk"
require "yaml"
require "logger"

class ChefAWS
    def initialize
        @logger = ::Logger.new(STDOUT).tap do |log|
            log.formatter = proc do |severity, time, progname, msg|
                "#{progname} - #{msg}\n"
            end
            log.level = Logger::INFO
            log.progname = 'ChefAWS'
        end

        @config = ::YAML.load_file( File.expand_path( "~/.aws/kitchen.yml") )
        @credentials = ::Aws::SharedCredentials.new(
            :profile_name => @config['driver']['shared_credentials_profile']
        )

        @rds = ::Aws::RDS::Client.new(
            region: @config['driver']['region'],
            credentials: @credentials
        )
    end

    def get_db_instance(id)
        instance = nil
        begin
            list = @rds.describe_db_instances(:db_instance_identifier => id)
            instance = list[:db_instances][0]
        rescue ::Aws::RDS::Errors::DBInstanceNotFound
            @logger.warn "No RDS instance #{id} for staging"
        end

        return instance
    end

    def create_db_instance(type)
        instance = self.get_db_instance("#{type.downcase}-staging")
        if instance.nil? then
            # create a new RDS instance
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
            @logger.info "Creating #{type.downcase}-staging RDS instance"
            sleep 10
            instance = get_db_instance("#{type}-staging")
        end

        while instance[:db_instance_status] == 'creating' do
            sleep 5
            @logger.info "Waiting for #{type.downcase}-staging to initialize (#{instance[:db_instance_status]}), retry in 5 seconds ..."
            instance = get_db_instance("#{type.downcase}-staging")
        end

        @logger.info "RDS creation finished with status: #{instance[:db_instance_status]}"
        @logger.info "DNS name: #{instance[:endpoint][:address]}"
        @logger.info "Port: #{instance[:endpoint][:port].to_s}"

        return instance
    end

end
