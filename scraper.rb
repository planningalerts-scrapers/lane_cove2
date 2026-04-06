#!/usr/bin/env ruby
# frozen_string_literal: true

Bundler.require

require "mechanize"
require "scraperwiki"

# Scraper for Lane Cove Council advertised DAs.
class Scraper
  BASE_URL = "https://ecouncil.lanecove.nsw.gov.au/trim/advertisedDAs-mobile.aspx"
  STATE = "NSW"

  FIELD_MAP = {
    "Development:" => "description",
    "Applicant:" => false, # ignored
    "Application #:" => "council_reference",
    "Advertised:" => "date_received",
  }.freeze

  def self.run
    agent = Mechanize.new
    agent.agent.set_proxy(ENV["MORPH_AUSTRALIAN_PROXY"]) if ENV["MORPH_AUSTRALIAN_PROXY"]

    page = agent.get(BASE_URL)
    bodypanel = page.at("div#bodypanel1")
    raise "Could not find bodypanel" unless bodypanel

    current_suburb = nil
    count = 0

    bodypanel.children.each do |node|
      next unless node.element?

      if node.name == "h2"
        current_suburb = node.text.gsub(/\s+/, " ").strip
        next
      end

      next unless node.name == "table" &&
                  node["class"]&.include?("tabular-data") &&
                  current_suburb

      record = parse_application(node, current_suburb)
      next unless record

      puts "Storing #{record['council_reference']} - #{record['address']}"
      ScraperWiki.save_sqlite(["council_reference"], record)
      count += 1
    end

    puts "Finished - processed #{count} records"
  end

  def self.parse_application(table, suburb)
    rows = table.search("tr").reject { |r| r["class"]&.include?("datatable_alternate") }
    street = rows.first.text.strip
    address = "#{street}, #{suburb} #{STATE}"

    record = { "address" => address, "date_scraped" => Date.today.to_s }

    rows.drop(1).each do |row|
      tds = row.search("td")
      next if tds.length < 3

      heading = tds[1].text.strip
      field = FIELD_MAP[heading]
      record[field] = tds[2].text.strip if field
      case field
      when "date_received"
        record.merge!(parse_dates(record[field]))
      when "council_reference"
        link = tds[2].at("a")
        record["info_url"] = link["href"]
      when nil
        puts "WARN: Unexpected heading: #{heading.inspect}"
        next
      end
    end

    unless record["council_reference"]
      puts "WARN: No council_reference found in table, skipping"
      return nil
    end

    record
  end

  # Parses "23/03/2026  Expiry: 07/04/2026" into date_received and on_notice_to
  def self.parse_dates(text)
    unless text =~ %r{(\d{2}/\d{2}/\d{4}).*Expiry:\s*(\d{2}/\d{2}/\d{4})}
      puts "WARN: Could not parse dates from: #{text.inspect}"
      return {}
    end

    {
      "date_received" => Date.strptime(Regexp.last_match(1), "%d/%m/%Y").to_s,
      "on_notice_to" => Date.strptime(Regexp.last_match(2), "%d/%m/%Y").to_s,
    }
  end
end

Scraper.run if __FILE__ == $PROGRAM_NAME
