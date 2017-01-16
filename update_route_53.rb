require 'aws-sdk'
require 'yaml'

config_path = ARGV.first

if config_path.nil? || config_path.empty?
  puts 'A path to a config file is required'
  exit
end

if !File.exist?(config_path)
  puts 'Config file does not exist'
  exit
end

config = YAML.load(File.read(config_path))

if config['zones'].nil? || config['zones'].empty?
  puts 'No zones specified'
  exit
end

public_ip = `dig TXT +short o-o.myaddr.l.google.com @ns1.google.com`.strip.gsub('"', '')

route53 = Aws::Route53::Client.new(region: config['region'])

config['zones'].each do |zone|
  changes = []
  zone['records'].each do |record|
    changes << {
      action: 'UPSERT',
      resource_record_set: {
        name: record['record_name'],
        type: record['record_type'],
        ttl: record['ttl'],
        resource_records: [
          {
            value: public_ip
          }
        ]
      }
    }
  end

  route53.change_resource_record_sets(
    hosted_zone_id: zone['zone_id'],
    change_batch: {
      comment: "Auto updated at #{Time.now}",
      changes: changes
    }
  )
end
