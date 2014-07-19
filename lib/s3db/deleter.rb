module S3db
  class Deleter

    attr_reader :config, :s3
    attr_reader :max_num_backups

    def initialize
      @config = configure
      @max_num_backups = @config.aws['max_num_backups']
    end

    def clean
      if max_num_backups
        open_s3_connection
        delete_extra_dumps
      end
    end

    private

    def configure
      S3db::Configuration.new
    end

    def open_s3_connection
      @s3 = RightAws::S3Interface.new(config.aws['aws_access_key_id'], config.aws['secret_access_key'])
    end

    def choose_bucket
      ENV['S3DB_BUCKET'] || config.aws['production']['bucket']
    end
    
    def delete_extra_dumps
      bucket = choose_bucket
      delete_dumps(bucket, deletable_dumps(bucket))
    end

    def all_dumps(bucket)
      all_dump_keys = s3.list_bucket(bucket, {:prefix => "mysql"})
      raise "No file with prefix 'mysql' found in bucket '#{bucket}'" if all_dump_keys.nil?
      all_dump_keys.sort { |a, b| a[:last_modified]<=>b[:last_modified] }
    end
    
    def deletable_dumps(bucket)
      all_dump_keys = all_dumps(bucket)
      last = all_dump_keys.length - max_num_backups - 1
      return [] if last<0
      all_dump_keys[0..last]
    end
    
    def delete_dumps(bucket, dumps)
      dumps.each do |dump|
        s3.delete(bucket, dump[:key])
      end
    end
    
  end
end