# Bookshark
![Bookshark Logo](https://dl.dropboxusercontent.com/u/4888041/bookshark/logo.png)

---------------------------------------------------------------------------------------------------

  NOTICE: This library is __under heavy development__, but is not funtional yet. Version 1.0.0.alpha will be ready soon.
  
---------------------------------------------------------------------------------------------------

A ruby library for book metadata extraction from biblionet.gr which
extracts books, authors, publishers and ddc metatdata.
The representation of bibliographic metadata in JSON is inspired by [BibJSON](http://okfnlabs.org/bibjson/) but some tags may be different.

## Installation(not working yet)

Add this line to your application's Gemfile:

```ruby
gem 'bookshark'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install bookshark

## Usage
Include bookshark in your class/module.
```ruby
include Bookshark
```
Alternatively you can use this syntax
```ruby
Bookshark::Extractor.new

# Instead of this
include Bookshark
Extractor.new
```

### Extractor

Create an extractor object
```ruby
Extractor.new
Extractor.new(format: 'json')
Extractor.new(format: 'hash', site: 'biblionet')
```
**Extractor Options**:
* format : The format in which the extracted data are returned
⋅⋅* hash (default)
⋅⋅* json
⋅⋅* pretty_json
* site : The site from where the metadata will be extracted
⋅⋅* biblionet (default and currently the only available, so it can be skipped)

#### Extract Book Data

You need book's id on biblionet website or its uri.
Currently more advanced search functions based on title and author are not available, but they will be until the stable version 1.0.0 release.

First create an extractor object:
```ruby
# Create a new extractor object with pretty json format.
extractor = Extractor.new(format: 'pretty_json')
```
Then you can extract books
```ruby
# Extract book with id 103788 from website
extractor.book(id: 103788)

# Extract book from the provided webpage 
extractor.book(uri: 'http://biblionet.gr/book/103788/')

# Extract book with id 103788 from local storage
extractor.book(id: 103788, local: true)
```

**Book Options**: (Recommended option is to use just the id and let bookshark to generate uri):
* id : The id of book on the corresponding site (Integer)
* uri : The url of book web page or the path to local file.
* local : Boolean value. Has page been saved locally? (default is false) 

The expected result of a book extraction is something like this:
```json
{
  "book": [
    {
      "title": "Σημεία και τέρατα της οικονομίας",
      "subtitle": "Η κρυφή πλευρά των πάντων",
      "image": "http://www.biblionet.gr/images/covers/b103788.jpg",
      "author": [
        {
          "name": "Steven D. Levitt",
          "b_id": "59782"
        },
        {
          "name": "Stephen J. Dubner",
          "b_id": "59783"
        }
      ],
      "contributors": {
        "μετάφραση": [
          {
            "name": "Άγγελος Φιλιππάτος",
            "b_id": "851"
          }
        ]
      },
      "publisher": "Εκδοτικός Οίκος Α. Α. Λιβάνη",
      "publication_year": "2006",
      "pages": "326",
      "isbn": "960-14-1157-7",
      "isbn_13": "978-960-14-1157-6",
      "status": "Κυκλοφορεί",
      "price": "16,31",
      "award": [

      ]
      "description": "Τι είναι πιο επικίνδυνο, ένα όπλο ή μια πισίνα; Τι κοινό έχουν οι δάσκαλοι με τους παλαιστές του σούμο;...",
      "categories": [
        {
          "ddc": "330",
          "text": "Οικονομία",
          "b_id": "142"
        }
      ],
      "b_id": "103788"
    }
  ]
}
```


#### Extract Author Data

You need author's id on biblionet website or his uri
```ruby
Extractor.new.author(id: 10207)
Extractor.new(format: 'json').author(uri: 'http://www.biblionet.gr/author/10207/')
```
Extraction from local saved html pages is also possible, but not recommended
```ruby
extractor = Extractor.new(format: 'json')
extractor.author(uri: 'storage/html_author_pages/2/author_2423.html', local: true)
```
**Author Options**: (Recommended option is to use just the id and let bookshark to generate uri):
* id : The id of author on the corresponding site (Integer)
* uri : The url of author web page or the path to local file.
* local : Boolean value. Has page been saved locally? (default is false) 

The expected result of an author extraction is something like this:
```json
{
  "author": [
    {
      "name": "Tolkien, John Ronald Reuel",
      "firstname": "John Ronald Reuel",
      "lastname": "Tolkien",
      "lifetime": "1892-1973",
      "image": "http://www.biblionet.gr/images/persons/10207.jpg",
      "bio": "Ο John Ronald Reuel Tolkien, άγγλος φιλόλογος και συγγραφέας, γεννήθηκε το 1892 στην πόλη Μπλουμφοντέιν...",
      "award": [
        {
          "name": "The Benson Medal [The Royal Society of Literature]",
          "year": "1966"
        }
      ],
      "b_id": "10207"
    }
  ]
}
```
The convention here is that there is never just a single author, but instead the author hash is stored inside an array. 
So, it is easy to include metadata for multiple authors or even for multiple types of entities such as publishers or books on the same json file.

#### Extract Publisher Data
Methods are pretty same as author:
```ruby
# Create a new extractor object with pretty json format.
extractor = Extractor.new(format: 'pretty_json')

# Extract publisher with id 20 from website
extractor.publisher(id: 20)

# Extract publisher from the provided webpage 
extractor.publisher(uri: 'http://biblionet.gr/com/20/')

# Extract publisher with id 20 from local storage
extractor.publisher(id: 20, local: true)
```
**Publisher Options**: (Recommended option is to use just the id and let bookshark to generate uri):
* id : The id of publisher on the corresponding site (Integer)
* uri : The url of publisher web page or the path to local file.
* local : Boolean value. Has page been saved locally? (default is false) 

The expected result of an author extraction is something like this:
```json
{
  "publisher": [
    {
      "name": "Εκδόσεις Πατάκη",
      "owner": "Στέφανος Πατάκης",
      "bookstores": {
        "Κεντρική διάθεση": {
          "address": [
            "Εμμ. Μπενάκη 16",
            "106 78 Αθήνα"
          ],
          "telephone": [
            "210 3831078"
          ]
        },
        "Γενικό βιβλιοπωλείο Πατάκη": {
          "address": [
            "Ακαδημίας 65",
            "106 78 Αθήνα"
          ],
          "telephone": [
            "210 3811850",
            "210 3811740"
          ]
        },
        "Έδρα": {
          "address": [
            "Παναγή Τσαλδάρη 38 (πρ. Πειραιώς)",
            "104 37 Αθήνα"
          ],
          "telephone": [
            "210 3650000",
            "210 5205600"
          ],
          "fax": "210 3650069",
          "email": "info@patakis.gr",
          "website": "www.patakis.gr"      	  
        }
      },
      "b_id": "20"
    }
  ]
}
```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/bookshark/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
