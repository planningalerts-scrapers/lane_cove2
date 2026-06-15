Lane Cove Council
========================

Lane Cove now has a custom web application that shows
"Development Applications Currently Advertised".
This means we don't see the applications just entered into the system.

This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)

Add any issues to https://github.com/planningalerts-scrapers/issues/issues

Optionally set `MORPH_AUSTRALIAN_PROXY` to an Australian proxy

## Expected Output 

    Storing DA194/2017 - 22 Bellevue Avenue, GREENWICH NSW
    Storing DA37/2023 - 14 Gatacre Avenue, LANE COVE NSW
    ...
    Storing DA30/2026 - 104 Tambourine Bay Road, RIVERVIEW NSW
    Storing DA24/2026 - 2 Pacific Highway, ST LEONARDS NSW
    Finished - processed 7 records

Expected runtime: ~ 5 seconds

## To run the scraper

    bundle exec ruby scraper.rb

## To run style and coding checks

    bundle exec rubocop

## To check for security updates

    gem install bundler-audit
    bundle-audit
