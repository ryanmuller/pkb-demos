# PKB Ruby Demos

## Usage

Clone the repository and run

```
bundle install
```

### Tumblr Import

Adapted from
[jsomers/semantic-notes](https://github.com/jsomers/semantic-notes).

`fetch_tumblr_data_and_populate_db` takes one argument, the domain of a
Tumblog (no http://). It creates a sqlite3 db of the same name with two
tables: notes and sources.

```
ruby fetch_tumblr_data_and_populate_db.rb effective-learning.tumblr.com
```

## Coming soon

### tf-idf

### Interest Graph API

