# Bookshark
![Bookshark Logo](https://dl.dropboxusercontent.com/u/4888041/bookshark/logo.png)

A ruby library for book metadata extraction from biblionet.gr which
extracts books, authors, publishers and ddc metatdata.
The representation of bibliographic metadata in JSON is inspired by [BibJSON](http://okfnlabs.org/bibjson/) but some tags may be different.

[![Build Status](https://travis-ci.org/dklisiaris/bookshark.svg?branch=master)](https://travis-ci.org/dklisiaris/bookshark)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bookshark', "~> 1.0.0.alpha"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install bookshark --pre

Require and include bookshark in your class/module.

```ruby
require 'bookshark'
class Foo
  include Bookshark
end
```
Alternatively you can use this syntax

```ruby
Bookshark::Extractor.new

# Instead of this
include Bookshark
Extractor.new
```

## Extractor
An extractor object must be created in order to perform any metadata extractions.

Create an extractor object

```ruby
Extractor.new
Extractor.new(format: 'json')
Extractor.new(format: 'hash', site: 'biblionet')
```
**Extractor Options**:

* format : The format in which the extracted data are returned
  * hash (default)
  * json
  * pretty_json
* site : The site from where the metadata will be extracted
  * biblionet (default and currently the only available, so it can be skipped)

### Extract Book Data

You need book's id on biblionet website or its uri.
First create an extractor object:

```ruby
# Create a new extractor object with pretty json format.
extractor = Extractor.new(format: 'pretty_json')
```
Then you can extract books

```ruby
# Extract book with isbn 960-14-1157-7 from website
extractor.book(isbn: '960-14-1157-7')

# ISBN-13 also works
extractor.book(isbn: '978-960-14-1157-6')

# ISBN without any dashes is ok too
extractor.book(isbn: '9789601411576')

# Extract book with id 103788 from website
extractor.book(id: 103788)

# Extract book from the provided webpage 
extractor.book(uri: 'http://biblionet.gr/book/103788/')

# Extract book with id 103788 from local storage
extractor.book(id: 103788, local: true)
```
For more options, like book's title or author, use the search method which is described below.

**Book Options** 
(Recommended option is to use just the id and let bookshark to generate uri):

* id : The id of book on the corresponding site (Integer)
* uri : The url of book web page or the path to local file.
* local : Boolean value. Has page been saved locally? (default is false) 
* format : The format in which the extracted data are returned
  * hash (default)
  * json
  * pretty_json
* eager : Perform eager extraction? (Boolean - default is false)

#### Eager Extraction

Each book has some attributes such as authors, contributors, categories etc which are actually references to other objects.   
By default when extracting a book, you get only names of these objects and references to their pages.   
With eager option set to true, each of these objects' data is extracted and the produced output contains complete information about every object.   
Eager extraction doesn't work with local option enabled.

```ruby
# Extract book with id 103788 with eager extraction option enabled
extractor.book(id: 103788, eager: true)
```

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
      "publisher": {
        "name": "Εκδοτικός Οίκος Α. Α. Λιβάνη",
        "b_id": "271"
      },
      "publication_year": "2006",
      "pages": "326",
      "isbn": "960-14-1157-7",
      "isbn_13": "978-960-14-1157-6",
      "status": "Κυκλοφορεί",
      "price": "16,31",
      "award": [
      ],
      "description": "Τι είναι πιο επικίνδυνο, ένα όπλο ή μια πισίνα; Τι κοινό έχουν οι δάσκαλοι με τους παλαιστές του σούμο;...",
      "category": [
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
Here is a [Book Sample](https://gist.github.com/dklisiaris/a6f3d6f37806186f3c79) extracted with eager option enabled.

### Book Search
Instead of providing the exact book id and extract that book directly, a search function can be used to get one or more books based on some parameters.

```ruby
# Create a new extractor object with pretty json format.
extractor = Extractor.new(format: 'pretty_json')

# Extract books with these words in title
extractor.search(title: 'σημεια και τερατα')

# Extract books with these words in title and this name in author
extractor.search(title: 'χομπιτ', author: 'τολκιν', results_type: 'metadata')

# Extract books from specific author, published after 1984
extractor.search(author: 'arthur doyle', after_year: '2010')

# Extract ids of books books with these words in title and this name in author
extractor.search(title: 'αρχοντας', author: 'τολκιν', results_type: 'ids')
```
Searching and extracting several books can be very slow at times, so instead of extracting every single book you may prefer only the ids of found books. In that case pass the option `results_type: 'ids'`.

**Search Options**:  
With enought options you can customize your query to your needs. It is recommended to use at least two of the search options.

* title (The title of book to search)       
* author (The author's last name is enough for filter the search)      
* publisher
* category
* title_split
  * 0 (The exact title phrase must by matched)
  * 1 (Default - All the words in title must be matched in whatever order)   
  * 2 (At least one word should match)
* book_id (Providing id means only one book should returned)      
* isbn         
* author_id (ID of the selected author)    
* publisher_id 
* category_id  
* after_year (Published this year or later)   
* before_year (Published this year or before)   
* results_type
  * metadata (Default - Every book is extracted and an array of metadata is returned)
  * ids (Only ids are returned)
* format : The format in which the extracted data are returned
  * hash (default)
  * json
  * pretty_json

Results with ids option look like that:

```json 
{
 "book": [
    "119000",
    "103788",
    "87815",
    "87812",
    "15839",
    "77381",
    "46856",
    "46763",
    "33301"
  ]
}
```
Normally results are multiple books like the ones in book extractors:

```json
{
  "book": [
    {
      "title": "Στης Χλόης τα απόκρυφα",
      "subtitle": "…και άλλα σημεία και τέρατα",
      "... Rest of Metadata ...": "... condensed ..."
    },
    {
      "title": "Σημεία και τέρατα της οικονομίας",
      "subtitle": "Η κρυφή πλευρά των πάντων",
      "... Rest of Metadata ...": "... condensed ..."     
    },
    {
      "title": "Και άλλα σημεία και τέρατα από την ιστορία",
      "subtitle": null,
      "... Rest of Metadata ...": "... condensed ..."
    },
    {
      "title": "Σημεία και τέρατα από την ιστορία",
      "subtitle": null,
      "... Rest of Metadata ...": "... condensed ..."      
    }
  ]
}
```

### Extract Author Data

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

### Extract Publisher Data
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
* format : The format in which the extracted data are returned
  * hash (default)
  * json
  * pretty_json

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
### Extract Categories
Biblionet's categories are based on [Dewey Decimal Classification](http://en.wikipedia.org/wiki/Dewey_Decimal_Classification). It is possible to extract these categories also as seen below.

```ruby
# Create a new extractor object with pretty json format.
extractor = Extractor.new(format: 'pretty_json')

# Extract category with id 1041 from website
extractor.category(id: 1041)

# Extract category from the provided webpage 
extractor.category(uri: 'http://biblionet.gr/index/1041/')

# Extract category with id 1041 from local storage
extractor.category(id: 1041, local: true)
```
**Categories Options**: (Pretty much the same as previous cases)

* id : The id of category on the corresponding site (Integer)
* uri : The url of category web page or the path to local file.
* local : Boolean value. Has page been saved locally? (default is false) 
* format : The format in which the extracted data are returned
  * hash (default)
  * json
  * pretty_json

Notice that when you are extracting a category you also extract parent categories and subcategories, thus you never extract just one category.

The expected result of a category extraction is something like this:
(Here the extracted category is the 1041, but parent and sub categories were also extracted.

```json
{
  "category": [
    {
      "192": {
        "ddc": "500",
        "name": "Φυσικές και θετικές επιστήμες",
        "parent": null
      },
      "1040": {
        "ddc": "520",
        "name": "Αστρονομία",
        "parent": "192"
      },
      "1041": {
        "ddc": "523",
        "name": "Πλανήτες",
        "parent": "1040"
      },
      "780": {
        "ddc": "523.01",
        "name": "Αστροφυσική",
        "parent": "1041"
      },
      "2105": {
        "ddc": "523.083",
        "name": "Πλανήτες - Βιβλία για παιδιά",
        "parent": "1041"
      },
      "576": {
        "ddc": "523.1",
        "name": "Κοσμολογία",
        "parent": "1041"
      },
      "current": {
        "ddc": "523",
        "name": "Πλανήτες",
        "parent": "1040",
        "b_id": "1041"
      }
    }
  ]
}
```
Notice that the last item is the current category. The rest is the category tree.

### Where do IDs point?
The id of each data type points to the corresponding type webpage.
Take a look at this table:

| ID      | Data Type   | Target Webpage                   |
|---------|:-----------:|----------------------------------|
| 103788  | book        | http://biblionet.gr/book/103788  |
| 10207   | author      | http://biblionet.gr/author/10207 |
| 20      | publisher   | http://biblionet.gr/com/20       | 
| 1041    | category    | http://biblionet.gr/index/1041   |

So if you want to use the uri option provide the target webpage's url as seen above without any slugs after th id.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/bookshark/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
