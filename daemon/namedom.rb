include RethinkDB::Shortcuts

class Namedom
  @@table = 'namedom'

  def self.all
    r.table(@@table).with_fields('id').run(@@conn).map do |id|
      Namedom.new(id['id'])
    end
  end

  def self.init(options = {})
    @@conn = r.connect options
    unless r.table_list.run(@@conn).include? @@table
      r.table_create(@@table).run(@@conn)
    end
  end

  attr_reader :name, :status, :issuance, :expiry
  attr_accessor :type, :domains

  def initialize(name)
    @name = name
    fetch!
  end

  def fetch!
    data = r.table(@@table).get(@name).run(@@conn)
    @exists = !data.nil?
    unless data.nil?
      @type = data['type']
      @status = data['status']
      @issuance = data['issuance']
      @expiry = data['expiry']
      @domains = data['domains'] || []
    end
  end

  def save!
    if @exists
      r.table(@@table)
        .get(@name)
        .update(type: @type, domains: @domains)
        .run(@@conn)
    else
      r.table(@@table).insert(
        id: @name,
        type: @type,
        domains: @domains,
        status: 'submitted'
      ).run(@@conn)
      @exists = true
    end
  end

  def delete!
    if @exists
      r.table(@@table).update(status: 'deleting').run(@@conn)
    end
  end

  def exists?
    @exists
  end

  def to_json(*args)
    {
      domains: @domains,
      expiry: @expiry,
      issuance: @issuance,
      name: @name,
      status: @status,
      type: @type
    }.to_json *args
  end
end
