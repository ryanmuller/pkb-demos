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

### Diigo Import

You'll need a Diigo account and [API key](https://www.diigo.com/api_dev/docs),
which you should put in a file called `secrets.yml` like so:

```
diigo_api_key: XXXXXX
diigo_username: rmuller
diigo_password: password
```

Now you can fetch your bookmarks and notes by passing your username.
This creates `com.diigo.rmuller.db` with the same schema as Tumblr
import:

```
ruby fetch_diigo_data_and_populate_db.rb rmuller
```

### Interest Graph API

You'll need an [API key](http://interest-graph.getprismatic.com/),
which you should put in a file called `secrets.yml` like so:

```
prismatic_api_token: XXXX
```

After importing sources into a db (e.g.
`effective-learning.tumblr.com.db` from tumblr import), this will assign
interests to each source in a `source_metadata` table. `--rebuild` will
drop and recreate the table in case you've changed the schema. (sorry no
migrations)

```
ruby create_metadata_for_sources.rb effective-learning.tumblr.com [--rebuild]
```

### tf-idf

Adapted from
[jsomers/semantic-notes](https://github.com/jsomers/semantic-notes).

After importing notes into a db, this creates a "semantic map" (via
.stash files) of [Tf-idf](http://en.wikipedia.org/wiki/Tf%E2%80%93idf)
statistics for words by note as well as notes by word:

```
ruby create_semantic_map_for_notes.rb effective-learning.tumblr.com
```

After creating the semantic maps, we generate the five most unique terms
for each note:

```
ruby create_metadata_for_notes.rb effective-learning.tumblr.com [--rebuild]
```

Note the maps are also good for searching notes by term.
