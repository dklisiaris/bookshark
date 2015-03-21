require_relative 'book_extractor'

module Biblionet
  module Extractors

    class Search < BookExtractor
      def initialize(options = {})
        perform_search(options) unless options.empty?
      end  

      def perform_search(options = {})
        search_url = build_search_url(options)
        load_page(URI.encode(search_url)) # Page gets loaded on @page variable.

        book_ids = []

        # No need to operate on whole page. Just on part containing the book.
        content_re = /<!-- CONTENT START -->.*<!-- CONTENT END -->/m
        if (content_re.match(@page)).nil?
          puts @page
        end
        content = content_re.match(@page)[0]

        nodeset = Nokogiri::HTML(content)                   
        nodeset.xpath("//a[@class='booklink' and @href[contains(.,'/book/') ]]").each do |item|
          book_ids << item['href'].split("/")[2] 
        end

        books = []

        if options[:results_type] == 'ids'
          return book_ids          
        elsif options[:results_type] == 'metadata'          
          book_ids.each do |id|
            url = "http://www.biblionet.gr/book/#{id}"
            books << load_and_extract_book(url)
          end                            
        end

        return books    
      end

      def build_search_url(options = {})
        title         = present?(options[:title])     ? options[:title].gsub(' ','+')     : ''
        author        = present?(options[:author])    ? options[:author].gsub(' ','+')    : ''
        publisher     = present?(options[:publisher]) ? options[:publisher].gsub(' ','+') : ''
        category      = present?(options[:category])  ? options[:category].gsub(' ','+')  : ''

        title_split   = options[:title_split]  ||= '1'
        book_id       = options[:book_id]      ||= ''
        isbn          = options[:isbn]         ||= ''        
        author_id     = options[:author_id]    ||= ''        
        publisher_id  = options[:publisher_id] ||= ''      
        category_id   = options[:category_id]  ||= ''
        after_year    = options[:after_year]   ||= ''
        before_year   = options[:before_year]  ||= ''

        url_builder = StringBuilder.new
        url_builder.append('http://www.biblionet.gr/main.asp?page=results')
        url_builder.append('&title=')
        url_builder.append(title)
        url_builder.append('&TitleSplit=')
        url_builder.append(title_split)
        url_builder.append('&Titlesid=')
        url_builder.append(book_id)
        url_builder.append('&isbn=')
        url_builder.append(isbn)
        url_builder.append('&person=')
        url_builder.append(author)
        url_builder.append('&person_ID=')
        url_builder.append(author_id)
        url_builder.append('&com=')
        url_builder.append(publisher)
        url_builder.append('&com_ID=')
        url_builder.append(publisher_id)
        url_builder.append('&from=')
        url_builder.append(after_year)        
        url_builder.append('&untill=')
        url_builder.append(before_year)
        url_builder.append('&subject=')
        url_builder.append(category)
        url_builder.append('&subject_ID=')
        url_builder.append(category_id)
        url_builder.build
      end 

      def present?(value)
        return (not value.nil? and not value.empty?) ? true : false
      end         

    end

    class StringBuilder      
      def initialize
        @string = []        
      end

      def append(text)
        @string << text
      end

      def build
        @string.join.to_s
      end
    end

  end
end


# require 'nokogiri'

# c = '<table width="780" border="0" cellpadding="10" cellspacing="0" bgcolor="#F7F7F7"><tr><td width="65" valign="top"><a href="/book/119000/Βασιλακάκος,_Γιάννης/Στης_Χλόης_τα_απόκρυφα"><img style="border: 1px solid #a9a9a9;" src="/images/covers/s119000.jpg" width="65" valign="top"></a></td><td valign="top"><b>Βασιλακάκος, Γιάννης</b>. <a class="booklink" href="/book/119000/Βασιλακάκος,_Γιάννης/Στης_Χλόης_τα_απόκρυφα">Στης Χλόης τα απόκρυφα</a> : …και άλλα <span class="searchstring">σημεία και τέρατα</span> / <a class="booklink" href="/author/22300/Γιάννης_Βασιλακάκος">Γιάννης Βασιλακάκος</a>. - 1η έκδ. - Αθήνα : <a class="booklink" href="/com/7628/Λογοσοφία">Λογοσοφία</a>, 2007. - 181σ.  · 21x14εκ.<br><br><span class="small">Διακίνηση: <a class="subjectlink" href="/com/7501/Μπατσιούλας_Ν._&_Σ."><em>Μπατσιούλας Ν. & Σ.</em></a>.<br>ISBN 978-960-89288-3-1 (Μαλακό εξώφυλλο) [Κυκλοφορεί]<br><nobr>&euro; 13,52</nobr> (Τελ. ενημ: 9/5/2007) · Η τιμή περιλαμβάνει Φ.Π.A. 6,5%.</I><br></span><br><a class="subjectlink" href="/index/3">Νεοελληνική πεζογραφία - Διήγημα   [DDC: 889.3]</a> <BR></table><table width="780" border="0" cellpadding="10" cellspacing="0" bgcolor="#e3e3e3"><tr><td width="65" valign="top"><a href="/book/103788/Levitt,_Steven_D./Σημεία_και_τέρατα_της_οικονομίας"><img style="border: 1px solid #a9a9a9;" src="/images/covers/s103788.jpg" width="65" valign="top"></a></td><td valign="top"><b>Levitt, Steven D.</b> <a class="booklink" href="/book/103788/Levitt,_Steven_D./Σημεία_και_τέρατα_της_οικονομίας"><span class="searchstring">Σημεία και τέρατα</span> της οικονομίας</a> : Η κρυφή πλευρά των πάντων / <a class="booklink" href="/author/59782/Steven_D._Levitt">Steven D. Levitt</a>, <a class="booklink" href="/author/59783/Stephen_J._Dubner">Stephen J. Dubner</a> · μετάφραση <a class="booklink" href="/author/851/Άγγελος_Φιλιππάτος">Άγγελος Φιλιππάτος</a>. - 1η έκδ. - Αθήνα : <a class="booklink" href="/com/271/Εκδοτικός_Οίκος_Α._Α._Λιβάνη">Εκδοτικός Οίκος Α. Α. Λιβάνη</a>, 2006. - 326σ.  · 21x14εκ. - (Οικονομία)<br><br><span class="small">Γλώσσα πρωτοτύπου: αγγλικά<br>Τίτλος πρωτοτύπου: Freakonomics<br>Περιέχει βιβλιογραφία<br>ISBN 960-14-1157-7, ISBN-13 978-960-14-1157-6 (Μαλακό εξώφυλλο) [Κυκλοφορεί]<br><nobr>&euro; 16,31</nobr> (Τελ. ενημ: 27/1/2006) · Η τιμή περιλαμβάνει Φ.Π.A. 6,5%.</I><br></span><br><a class="subjectlink" href="/index/142">Οικονομία   [DDC: 330]</a> <BR></table><table width="780" border="0" cellpadding="10" cellspacing="0" bgcolor="#F7F7F7"><tr><td width="65" valign="top"><a href="/book/87815/Wood,_Tim/Και_άλλα_σημεία_και_τέρατα_από_την_ιστορία"><img style="border: 1px solid #a9a9a9;" src="/images/covers/s87815.jpg" width="65" valign="top"></a></td><td valign="top"><b>Wood, Tim</b>. <a class="booklink" href="/book/87815/Wood,_Tim/Και_άλλα_σημεία_και_τέρατα_από_την_ιστορία">Και άλλα <span class="searchstring">σημεία και τέρατα</span> από την ιστορία</a> / <a class="booklink" href="/author/51043/Tim_Wood">Tim Wood</a>, <a class="booklink" href="/author/3047/Ian_Dicks">Ian Dicks</a> · μετάφραση <a class="booklink" href="/author/34013/Χριστίνα_Ελιασά">Χριστίνα Ελιασά</a>.  - Αθήνα : <a class="booklink" href="/com/191/Modern_Times">Modern Times</a>, 2004. - 62σ. : εικ.  · 28x22εκ.<br><br><span class="small">τ.2<br>Γλώσσα πρωτοτύπου: αγγλικά<br>Τίτλος πρωτοτύπου: Even more horrible history<br>ISBN 960-397-927-9, ISBN-13 978-960-397-927-2 (Σκληρό εξώφυλλο) [Κυκλοφορεί]<br><nobr>&euro; 15,14</nobr> · Η τιμή περιλαμβάνει Φ.Π.A. 6,5%.</I><br></span><br><a class="subjectlink" href="/index/2456">Παιδικά βιβλία, Μεταφρασμένα  [DDC: 899.91]</a> <BR></table><table width="780" border="0" cellpadding="10" cellspacing="0" bgcolor="#e3e3e3"><tr><td width="65" valign="top"><a href="/book/87812/Wood,_Tim/Σημεία_και_τέρατα_από_την_ιστορία"><img style="border: 1px solid #a9a9a9;" src="/images/covers/s87812.jpg" width="65" valign="top"></a></td><td valign="top"><b>Wood, Tim</b>. <a class="booklink" href="/book/87812/Wood,_Tim/Σημεία_και_τέρατα_από_την_ιστορία"><span class="searchstring">Σημεία και τέρατα</span> από την ιστορία</a> / <a class="booklink" href="/author/51043/Tim_Wood">Tim Wood</a>, <a class="booklink" href="/author/3047/Ian_Dicks">Ian Dicks</a> · μετάφραση <a class="booklink" href="/author/34013/Χριστίνα_Ελιασά">Χριστίνα Ελιασά</a>.  - Αθήνα : <a class="booklink" href="/com/191/Modern_Times">Modern Times</a>, 2004. - 78σ.  · 28x22εκ.<br><br><span class="small">τ.1<br>Γλώσσα πρωτοτύπου: αγγλικά<br>Τίτλος πρωτοτύπου: Horrible history<br>ISBN 960-397-926-0, ISBN-13 978-960-397-926-5 (Σκληρό εξώφυλλο) [Κυκλοφορεί]<br><nobr>&euro; 15,14</nobr> · Η τιμή περιλαμβάνει Φ.Π.A. 6,5%.</I><br></span><br><a class="subjectlink" href="/index/2456">Παιδικά βιβλία, Μεταφρασμένα  [DDC: 899.91]</a> <BR></table><table width="780" border="0" cellpadding="10" cellspacing="0" bgcolor="#F7F7F7"><tr><td width="65" valign="top"><a href="/book/15839/Αμπατζόγλου,_Πέτρος,_1931-2004/Σημεία_και_τέρατα"><img style="border: 1px solid #a9a9a9;" src="/images/covers/s15839.jpg" width="65" valign="top"></a></td><td valign="top"><b>Αμπατζόγλου, Πέτρος, 1931-2004</b>. <a class="booklink" href="/book/15839/Αμπατζόγλου,_Πέτρος,_1931-2004/Σημεία_και_τέρατα"><span class="searchstring">Σημεία και τέρατα</span></a> / <a class="booklink" href="/author/11916/Πέτρος_Αμπατζόγλου">Πέτρος Αμπατζόγλου</a>. - 2η έκδ. - Αθήνα : <a class="booklink" href="/com/21/Κέδρος">Κέδρος</a>, 1994. - 126σ.  · 21x14εκ.<br><br><span class="small">1η έκδοση: 1981.<br>Αναθεωρημένη έκδοση.<br>ISBN 960-04-0941-2, ISBN-13 978-960-04-0941-3 (Μαλακό εξώφυλλο) [Κυκλοφορεί]<br><nobr>&euro; 9,17</nobr> (Τελ. ενημ: 28/7/2010) · Η τιμή περιλαμβάνει Φ.Π.A. 6,5%.</I><br></span><br><a class="subjectlink" href="/index/9">Νεοελληνική πεζογραφία - Μυθιστόρημα  [DDC: 889.3]</a> <BR></table><table width="780" border="0" cellpadding="10" cellspacing="0" bgcolor="#e3e3e3"><tr><td width="65" valign="top"><a href="/book/77381/Σταφυλάς,_Μιχάλης/Επίσημη_αγραμματοσύνη"><img style="border: 1px solid #a9a9a9;" src="/images/covers/s77381.jpg" width="65" valign="top"></a></td><td valign="top"><b>Σταφυλάς, Μιχάλης</b>. <a class="booklink" href="/book/77381/Σταφυλάς,_Μιχάλης/Επίσημη_αγραμματοσύνη">Επίσημη αγραμματοσύνη</a> : Ήτοι <span class="searchstring">σημεία και τέρατα</span> δημοσίων εγγράφων συλλεγέντα υπό γραφειοκράτου διευθυντού υπουργείου / <a class="booklink" href="/author/27875/Μιχάλης_Σταφυλάς">Μιχάλης Σταφυλάς</a>.  - Αθήνα : <a class="booklink" href="/com/6770/Περιοδικό_Πνευματική_Ζωή">Περιοδικό Πνευματική Ζωή</a>, <nobr>[χ.χ.].</nobr> - 48σ.  · 24x17εκ. - (Νεοελληνικά Αφιερώματα · 21)<br><br><span class="small">Εκτός εμπορίου.<br>(Μαλακό εξώφυλλο) [Κυκλοφορεί]<br></span><br><a class="subjectlink" href="/index/1459">Αρχεία - Ιστορία - Ελλάς   [DDC: 027.094 95]</a> <BR></table><table width="780" border="0" cellpadding="10" cellspacing="0" bgcolor="#F7F7F7"><tr><td width="65" valign="top"><img src="/images/1px.gif" width="65" valign="top"></td><td valign="top"><b>Yermak, D. C.</b> <a class="booklink" href="/book/46856/Yermak,_D._C./Ο_όλεθρος_της_πυραμίδος_Καμπαλά">Ο όλεθρος της πυραμίδος Καμπαλά</a> : <span class="searchstring">Σημεία και τέρατα</span> στην νέα εποχή / <a class="booklink" href="/author/33200/D._C._Yermak">D. C. Yermak</a> · μετάφραση <a class="booklink" href="/author/33233/Ανδρεαδάκης_Γεράσιμος">Ανδρεαδάκης Γεράσιμος</a>.  - Θεσσαλονίκη : <a class="booklink" href="/com/244/Μπίμπης_Στερέωμα">Μπίμπης Στερέωμα</a>, <nobr>[χ.χ.].</nobr> - 269σ. : εικ.  · 21x14εκ.<br><br><span class="small">(Μαλακό εξώφυλλο) [Κυκλοφορεί]<br><nobr>&euro; 6,85</nobr> · Η τιμή περιλαμβάνει Φ.Π.A. 6,5%.</I><br></span><br><a class="subjectlink" href="/index/179">Καμπαλά  [DDC: 296.712]</a> <BR></table><table width="780" border="0" cellpadding="10" cellspacing="0" bgcolor="#e3e3e3"><tr><td width="65" valign="top"><img src="/images/1px.gif" width="65" valign="top"></td><td valign="top"><b>Tse Sirp II</b>. <a class="booklink" href="/book/46763/Tse_Sirp_II/Η_επανάσταση_κατά_της_νέας_τάξης">Η επανάσταση κατά της νέας τάξης</a> : Αρχαίοι Έλληνες, λευκό αδελφάτο, πόλεμος των άστρων, ηλεκτρονικοί υπολογισταί, <span class="searchstring">σημεία και τέρατα</span>, τέλος νέας εποχής / <a class="booklink" href="/author/33182/Tse_Sirp_II">Tse Sirp II</a>.  - Θεσσαλονίκη : <a class="booklink" href="/com/244/Μπίμπης_Στερέωμα">Μπίμπης Στερέωμα</a>, <nobr>[χ.χ.].</nobr> - 71σ.  · 21x14εκ.<br><br><span class="small">C: Ανατολική Ευρώπη<br>(Μαλακό εξώφυλλο) [Κυκλοφορεί]<br><nobr>&euro; 3,73</nobr> · Η τιμή περιλαμβάνει Φ.Π.A. 6,5%.</I><br></span><br><a class="subjectlink" href="/index/2336">Πολιτική - Λόγοι, δοκίμια, διαλέξεις  [DDC: 320]</a> <BR></table><table width="780" border="0" cellpadding="10" cellspacing="0" bgcolor="#F7F7F7"><tr><td width="65" valign="top"><img src="/images/1px.gif" width="65" valign="top"></td><td valign="top"><b>Ντελόπουλος, Κυριάκος, 1933-</b>. <a class="booklink" href="/book/33301/Ντελόπουλος,_Κυριάκος,_1933-/Επιχείρησις:_Μαργαριτάρια">Επιχείρησις: Μαργαριτάρια</a> : Νεοελληνικά <span class="searchstring">σημεία και τέρατα</span> / <a class="booklink" href="/author/14602/Κυριάκου_Ντελόπουλου">Κυριάκου Ντελόπουλου</a>.  - Αθήνα : <a class="booklink" href="/com/1/Δωδώνη_Εκδοτική_ΕΠΕ">Δωδώνη Εκδοτική ΕΠΕ</a>, <nobr>[χ.χ.].</nobr> - 188σ.  · 20x13εκ.<br><br><span class="small">Πρόλογος Φρέντυ Γερμανού<br>ISBN 960-248-541-8, ISBN-13 978-960-248-541-5 (Μαλακό εξώφυλλο) [Κυκλοφορεί]<br><nobr>&euro; 10,60</nobr> · Η τιμή περιλαμβάνει Φ.Π.A. 6,5%.</I><br></span><br><a class="subjectlink" href="/index/1309">Ελληνική γλώσσα - Λόγοι, δοκίμια, διαλέξεις  [DDC: 480]</a> <BR></table><br/>'
# c = '<a href="/book/119000/Βασιλακάκος,_Γιάννης/Στης_Χλόης_τα_απόκρυφα"><img style="border: 1px solid #a9a9a9;" src="/images/covers/s119000.jpg" width="65" valign="top"></a></td><td valign="top"><b>Βασιλακάκος, Γιάννης</b>. <a class="booklink" href="/book/119000/Βασιλακάκος,_Γιάννης/Στης_Χλόης_τα_απόκρυφα">Στης Χλόης τα απόκρυφα</a> : …και άλλα <span class="searchstring">σημεία και τέρατα</span> / <a class="booklink" href="/author/22300/Γιάννης_Βασιλακάκος">Γιάννης Βασιλακάκος</a>. - 1η έκδ. - Αθήνα : <a class="booklink" href="/com/7628/Λογοσοφία">Λογοσοφία</a>, 2007. - 181σ.  · 21x14εκ.<br><br><span class="small">Διακίνηση: <a class="subjectlink" href="/com/7501/Μπατσιούλας_Ν._&_Σ."><em>Μπατσιούλας Ν. & Σ.</em></a>.<br>ISBN 978-960-89288-3-1 (Μαλακό εξώφυλλο) [Κυκλοφορεί]<br><nobr>&euro; 13,52</nobr> (Τελ. ενημ: 9/5/2007) · Η τιμή περιλαμβάνει Φ.Π.A. 6,5%.</I><br></span><br><a class="subjectlink" href="/index/3">Νεοελληνική πεζογραφία - Διήγημα   [DDC: 889.3]</a> <BR></table><table width="780" border="0" cellpadding="10" cellspacing="0" bgcolor="#e3e3e3"><tr><td width="65" valign="top"><a href="/book/103788/Levitt,_Steven_D./Σημεία_και_τέρατα_της_οικονομίας"><img style="border: 1px solid #a9a9a9;" src="/images/covers/s103788.jpg" width="65" valign="top"></a></td><td valign="top"><b>Levitt, Steven D.</b> <a class="booklink" href="/book/103788/Levitt,_Steven_D./Σημεία_και_τέρατα_της_οικονομίας"><span class="searchstring">Σημεία και τέρατα</span> της οικονομίας</a> : Η κρυφή πλευρά των πάντων / <a class="booklink" href="/author/59782/Steven_D._Levitt">Steven D. Levitt</a>'
# n = Nokogiri::HTML(c)
# n.xpath("//a[@class='booklink' and @href[contains(.,'/book/') ]]").each do |item|
#   puts item['href'].split("/")[2] 
# end