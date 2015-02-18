# PKB Ruby Demos

## Usage

Clone the repository and run

```
bundle install
```

### Tumblr Import

Adapted from
[jsomers/semantic-notes](https://github.com/jsomers/semantic-notes).

Takes one argument, the domain of a tumblog (no http://). It creates a
sqlite3 db of the same name with two tables: notes and sources.

```
ruby fetch_tumblr_data_and_populate_db.rb effective-learning.tumblr.com
```

### Interest Graph API

After importing sources into a db (e.g.
`effective-learning.tumblr.com.db` from tumblr import), this will assign
interests to each source in a `source_metadata` table. `--rebuild` will
drop and recreate the table in case you've changed the schema. (sorry no
migrations)

```
ruby create_metadata_for_sources.rb effective-learning.tumblr.com [--rebuild]
```

## Coming soon

### tf-idf
