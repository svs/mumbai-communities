namespace :officials do
  desc "Seed ward officials and corporators with real names and contact data"
  task seed: :environment do
    # Ward AC contact info (names not publicly available, using office contact)
    ward_contacts = {
      "A" => { phone: "022-22607000", email: "ac.a@mcgm.gov.in" },
      "B" => { phone: "022-23736622", email: "ac.b@mcgm.gov.in" },
      "C" => { phone: "022-22014022", email: "ac.c@mcgm.gov.in" },
      "D" => { phone: "022-23861426", email: "ac.d@mcgm.gov.in" },
      "E" => { phone: "022-23081471", email: "ac.e@mcgm.gov.in" },
      "F SOUTH" => { phone: "022-24134560", email: "ac.fs@mcgm.gov.in" },
      "F NORTH" => { phone: "022-24024353", email: "ac.fn@mcgm.gov.in" },
      "G SOUTH" => { phone: "022-24301831", email: "ac.gs@mcgm.gov.in" },
      "G NORTH" => { phone: "022-26842949", email: "ac.gn@mcgm.gov.in" },
      "H EAST" => { phone: "022-26514466", email: "ac.he@mcgm.gov.in" },
      "H WEST" => { phone: "022-26400924", email: "ac.hw@mcgm.gov.in" },
      "K EAST" => { phone: "022-26821001", email: "ac.ke@mcgm.gov.in" },
      "K WEST" => { phone: "022-26046050", email: "ac.kw@mcgm.gov.in" },
      "L" => { phone: "022-25226100", email: "ac.l@mcgm.gov.in" },
      "M EAST" => { phone: "022-25563907", email: "ac.me@mcgm.gov.in" },
      "M WEST" => { phone: "022-25012756", email: "ac.mw@mcgm.gov.in" },
      "N" => { phone: "022-25911421", email: "ac.n@mcgm.gov.in" },
      "P NORTH" => { phone: "022-26312530", email: "ac.pn@mcgm.gov.in" },
      "P SOUTH" => { phone: "022-26149656", email: "ac.ps@mcgm.gov.in" },
      "R/CENTRAL" => { phone: "022-28542406", email: "ac.rc@mcgm.gov.in" },
      "R SOUTH" => { phone: "022-28051841", email: "ac.rs@mcgm.gov.in" },
      "S" => { phone: "022-28721401", email: "ac.s@mcgm.gov.in" },
      "T" => { phone: "022-25895811", email: "ac.t@mcgm.gov.in" }
    }

    # Corporator data: [ward_code_from_source, prabhag_number, name, phone]
    # Source: BMC public directory
    corporators_raw = <<~DATA
      A|225|Sanap Sujata Digvijay|9870040562
      A|226|Harshita Narvekar|9619995533
      A|227|Makrand Narvekar|9833105553
      B|223|Gyanraj Nikita Nikam|9819358628
      B|224|Afreen Lakdawala|9892553553
      C|220|Shah Atul Hasmukhlal|9820145496
      C|221|Purohit Akash Raj|9820896296
      C|222|Makwana Rita Bharat|9820453885
      D|214|Sarita Ajay Patil|9930598086
      D|215|Arundhati Dudhwadkar|9619205654
      D|216|Rajendra Narvankar|9869066444
      D|217|Meena Patil|9595099072
      D|218|Anuradha Poddar|9869334406
      D|219|Jyotsana Mehta|8879997618
      E|207|Surekha Rohitdas Lokhande|9967835279
      E|208|Ramakant Sakharam Rahate|9322210707
      E|209|Yashwant Jadhav|9987147222
      E|210|Jamsutkar Sonam Manoj|9870537490
      E|211|Raees Kasam Sheikh|9819794747
      E|212|Geeta Gavli|9967912775
      E|213|Javed Juneja|9820366797
      F-North|172|Rajshree Shirvadkar|9869852149
      F-North|173|Prahlad Thombre|8433544022
      F-North|174|Krishnaveni Vinod Reddy|9321221692
      F-North|175|Mangesh Satamkar|9769656248
      F-North|176|Ravi Raja|9820047803
      F-North|177|Nehal Shah|9820367744
      F-North|178|Amey Ghole|9820893792
      F-North|179|Sufiyana Vanu Niyaz Ahmed|9833299067
      F-North|180|Smita Gavkar|9930589888
      F-North|181|Pushpa Kohli|9324157071
      F-South|200|Urmila Panchal|9821890099
      F-South|201|More Supriya|9322270542
      F-South|202|Shraddha Jadhav|9820702555
      F-South|203|Sindhu Masurkar|9869551334
      F-South|204|Anil Kokil|7039081155
      F-South|205|Datta Pongade|9819096162
      F-South|206|Sachin Devdas Padwal|9769194488
      G-North|182|Milind Dattaram Vaidya|9821137030
      G-North|183|Ganga Kunal Mane|7900099111
      G-North|184|Babbu Khan|9920970843
      G-North|185|Jagdish Makkunny Thaivalapill|9819522105
      G-North|186|Vasant Nakashe|9820142590
      G-North|187|Thevar Mariammal Mathuramlingan|9867202425
      G-North|188|Reshambano Mohammadhasim Khan|9029647006
      G-North|189|Harshala Ashish More|9765242754
      G-North|190|Sheetal Gambhir|9819059396
      G-North|191|Vishakha Raut|9821123801
      G-North|192|Priti Prakash Patankar|9321119777
      G-South|193|Hemangi Worlikar|9869209974
      G-South|194|Samadhan Sarwankar|9821447777
      G-South|195|Santosh Kharat|9867857237
      G-South|196|Ashish Chemburkar|9819800989
      G-South|197|Datta Narvankar|9969190021
      G-South|198|Snehal Ambekar|8879997194
      G-South|199|Kishori Pednekar|9869019232
      H-East|87|Vishwanath Pandurang Mahadeshwar|9869824264
      H-East|88|Sada Parab|9821678278
      H-East|89|Dinesh Kubal|9769682872
      H-East|90|Tulip Miranda|9820377639
      H-East|91|Sagun Naik|9869392701
      H-East|92|Gulnaz Salim Qureshi|9987967692
      H-East|93|Rohini Kamble|9930035121
      H-East|94|Pradnya Bhutkar|9833985735
      H-East|95|Chandrashekhar Vaingankar|9224216098
      H-East|96|Mohammed Halim Shamim Sheikh|9920919292
      H-West|97|Hetal Vimal Gala|9820383435
      H-West|98|Alka Subhash Kerkar|9820085844
      H-West|99|Sanjay Gulabrao Agaldare|9820866432
      H-West|100|Swapna Mhatre|9833815015
      H-West|101|Asif Ahmed Zakaria|9820125638
      H-West|102|Mumtaz Rahebar Khan|9004303852
      K-East|72|Pankaj Yadav|9833934109
      K-East|73|Pravin Shinde|9820700373
      K-East|74|Ujjawala Modak|9820333203
      K-East|75|Priyanka Sawant|9819467747
      K-East|76|Kesarben Murji Patel|9820647334
      K-East|77|Anant Nar|9702597025
      K-East|78|Sofi Jabbar|9870056757
      K-East|79|Sadanand Parab|9969045550
      K-East|80|Sunil Yadav|9819233414
      K-East|81|Murji Patel|9820130950
      K-East|82|Jagdish Amin|9869681553
      K-East|83|Vinnie D'souza|9892525885
      K-East|84|Abhijeet Samant|9619521872
      K-East|85|Jyoti Alwani|9819203553
      K-East|86|Sushma Kamlesh Rai|9820006069
      K-West|59|Pratima Khopde|8424032454
      K-West|60|Yogiraj Dabhadkar|9987579801
      K-West|61|Rajul Patel|9323801469
      K-West|62|Raju Pednekar|9820878555
      K-West|63|Ranjana Patil|9920114099
      K-West|64|Shahida Haroon Khan|9820186613
      K-West|65|Alpha Ashok Jadhav|9892480909
      K-West|66|Meher Mohsin Haider|9987085263
      K-West|67|Sudha Singh|9920486240
      K-West|68|Rohan Rathod|8898065170
      K-West|69|Renu Bhasin|9819000388
      K-West|70|Sunita Mehta|9821012833
      K-West|71|Anish Makhwani|9833387555
      L|156|Ashwini Matekar|9869182370
      L|157|Akanksha Shetty|7506252825
      L|158|Chitra Sangle|9821166962
      L|159|Prakash Devji More|9820634930
      L|160|Kiran Landge|9930513335
      L|161|Vijyandra Shinde|7303366123
      L|162|Wajid Kureshi|9769905283
      L|163|Dilip Bhausaheb Lande|9833201646
      L|164|Harish Bhandirge|9892821293
      L|165|Ashraf Azmi|9867004549
      L|166|Sanjay Turde|9833635403
      L|167|Dilshadbanu Mohammedashraf Azmi|9892759549
      L|168|Saida Khan|9167465192
      L|169|Pravina Manish Morajkar|8655867388
      L|170|Kaptan Malik|9821238787
      L|171|Sanvee Vijay Tandel|9969457915
      M-East|134|Saira Khan|9821886477
      M-East|135|Sameeksha Sakre|9820880441
      M-East|136|Rukshsana Siddique|9833371092
      M-East|137|Ayesha Rafique Shaikh|9987866594
      M-East|138|Ayeshabano Ainmohammed Khan|7021442137
      M-East|139|Akhtar Kureishi|8652267752
      M-East|140|Nadiya Mohsin Sheikh|9619792499
      M-East|141|Vithal Govind Lokare|9819821091
      M-East|142|Vaishali Shewale|9324252767
      M-East|143|Rutuja Tiwari|9167339209
      M-East|144|Anita Panchal|9821831831
      M-East|145|Shahnawaz Sheikh|9967000750
      M-East|146|Samruddhi Kate|9702233385
      M-East|147|Anjali Naik|9821494139
      M-East|148|Nidhi Shinde|9702473131
      M-West|149|Susham Sawant|9819956462
      M-West|150|Sangeeta Chandrakant Handore|9833383814
      M-West|151|Rajesh Phulvariya|9819884271
      M-West|152|Asha Subhash Marathe|9702535651
      M-West|153|Anil Patankar|9821360184
      M-West|154|Mahadev Shankar Shivgan|9820187496
      M-West|155|Shrikant Shettye|8108282838
      N|123|Snehal More|9833903330
      N|124|Jyoti Khan|9819813940
      N|125|Rupali Suresh Aawale|8268444653
      N|126|Archana Bhalerao|9867279645
      N|127|Suresh Patil|9867488555
      N|128|Ashwini Deepak Hande|9967107107
      N|129|Suryakant Gavli|9320006031
      N|130|Bindu Chetan Trivedi|9821342273
      N|131|Rakhee Harishchandra Jadhav|9820035419
      N|132|Parag Shah|9324911111
      N|133|Parmeshwar Tukaram Kadam|9870740909
      P-North|32|Steffi Kini|9833622058
      P-North|33|Virendra Chowdhary|9821406135
      P-North|34|Kamarjaha Siddique|9594326006
      P-North|35|Sejal Desai|9819387282
      P-North|36|Daksha Patel|8767466006
      P-North|37|Pratibha Shinde|8108608117
      P-North|38|Aatmaram Chache|9892585728
      P-North|39|Vinaya Vishnu Sawant|8097805551
      P-North|40|Suhas Wadkar|9987424633
      P-North|41|Tulsiram Shinde|9821066305
      P-North|42|Dhanashree Bharadkar|9833707507
      P-North|43|Vinod Mishra|9867800002
      P-North|44|Sangita Gyanmurti Mishra|9920714946
      P-North|45|Ram Barot|9869080789
      P-North|46|Yogita Sunil Koli|9869418206
      P-North|47|Jaya Tiwana|9987444344
      P-North|48|Salma Almelkar|9870405782
      P-North|49|Sangita Sutar|8454955099
      P-South|50|Deepak Thakur|9819372255
      P-South|51|Swapnil Mohan Tembwalkar|9821930417
      P-South|52|Priti Satam|9594069001
      P-South|53|Rekha Ramvanshi|9757363620
      P-South|54|Sadhna Mane|9324477452
      P-South|55|Harsh Patel|9892062221
      P-South|56|Rajul Sameer Desai|9833131866
      P-South|57|Shrikala Pillai|9867321181
      P-South|58|Sandip Patel|9833975393
      R-North|1|Tejaswini Ghosalkar|9730640127
      R-North|2|Jagdish Ojha|9821081417
      R-North|3|Balkrishna Brid|9820342259
      R-North|4|Sujata Patekar|9920758787
      R-North|5|Sanjay Ghadi|9821270669
      R-North|6|Harshal Kakkar|8452811611
      R-North|7|Sheetal Mhatre|9870337777
      R-North|8|Harish Chheda|9869011236
      R-Central|9|Shweta Sharad Korgaonkar|9869142749
      R-Central|10|Jitendra Ambalal Patel|9867619595
      R-Central|11|Riddhi Khursange|9869664997
      R-Central|12|Geeta Singhan|9702176525
      R-Central|13|Vidyarthi Singh|9820078393
      R-Central|14|Asawari Patil|8879997012
      R-Central|15|Pravin Shah|9322704829
      R-Central|16|Anjali Khedekar|7738046426
      R-Central|17|Beena Doshi|9870479227
      R-Central|18|Sandhya Doshi|9821117777
      R-South|19|Shubhada Gudekar|9820397011
      R-South|20|Deepak Tawade|9821330570
      R-South|21|Pratibha Girkar|9769958982
      R-South|22|Priyanka More|9221814146
      R-South|23|Shiv Kumar Jha|9323042901
      R-South|24|Sunita Yadav|9969511646
      R-South|25|Madhuri Bhoir|9833547778
      R-South|26|Pritam Pandagle|8108702993
      R-South|27|Surekha Patil|9969487390
      R-South|28|Rajpati Yadav|9820053894
      R-South|29|Thakur Sagar Singh|9833890397
      R-South|30|Leena Patil Deherkar|9819727178
      R-South|31|Kamlesh Yadav|9820331378
      S|109|Deepali Gosavi|9967179940
      S|110|Asha Koparkar|9869680333
      S|111|Sarika Pawar|9920106555
      S|112|Sakshi Deepak Dalvi|9323295097
      S|113|Deepmala Badhe|9820389686
      S|114|Ramesh Korgaonkar|9867379009
      S|115|Umesh Mane|9892411850
      S|116|Pramila Patil|9930145502
      S|117|Suvarna Karanje|9821913889
      S|118|Upendra Sawant|9819397676
      S|119|Manisha Harishchandra Rahate|9892289486
      S|120|Rajeshree Redkar|9820981827
      S|121|Chandravati More|9833860679
      S|122|Vaishali Patil|9833898990
      T|103|Manoj Kotak|9821163742
      T|104|Prakash Gangadhare|9820026347
      T|105|Rajani Keni|9664771110
      T|106|Prabhakar Tukaram Shinde|9819502777
      T|107|Smita Kamble|9820754224
      T|108|Neil Somaiya|9967592582
    DATA

    # Map source ward codes to our database ward codes
    SOURCE_TO_DB_WARD = {
      "A" => "A", "B" => "B", "C" => "C", "D" => "D", "E" => "E",
      "F-North" => "F NORTH", "F-South" => "F SOUTH",
      "G-North" => "G NORTH", "G-South" => "G SOUTH",
      "H-East" => "H EAST", "H-West" => "H WEST",
      "K-East" => "K EAST", "K-West" => "K WEST",
      "L" => "L",
      "M-East" => "M EAST", "M-West" => "M WEST",
      "N" => "N",
      "P-North" => "P NORTH", "P-South" => "P SOUTH",
      "R-North" => "R/North", "R-Central" => "R/Central", "R-South" => "R SOUTH",
      "S" => "S", "T" => "T"
    }.freeze

    puts "Seeding ward officials..."

    # Seed ACs
    ac_created = 0
    ward_contacts.each do |ward_code, contact|
      ward = Ward.find_by(ward_code: ward_code)
      unless ward
        puts "  Ward #{ward_code} not found, skipping AC"
        next
      end

      person = Person.find_or_initialize_by(email: contact[:email])
      person.name = "Ward #{ward.short_name || ward_code} Office" if person.new_record?
      person.phone = contact[:phone]
      person.save!

      role = Role.find_or_initialize_by(person: person, roleable: ward, role_name: "ward_office")
      if role.new_record?
        role.save!
        ac_created += 1
      end
    end
    puts "  Ward offices: #{ac_created} created"

    # Seed corporators with real names
    corp_created = 0
    corp_updated = 0
    corp_skipped = 0

    corporators_raw.strip.each_line do |line|
      parts = line.strip.split("|")
      next if parts.length < 4

      source_ward, prabhag_num, name, phone = parts
      prabhag_num = prabhag_num.to_i
      db_ward_code = SOURCE_TO_DB_WARD[source_ward]

      unless db_ward_code
        puts "  Unknown source ward: #{source_ward}"
        corp_skipped += 1
        next
      end

      ward = Ward.find_by(ward_code: db_ward_code)
      unless ward
        puts "  Ward #{db_ward_code} not found for corporator #{name}"
        corp_skipped += 1
        next
      end

      # Find or create person by phone (more stable than email for corporators)
      person = Person.find_or_initialize_by(phone: phone)
      if person.new_record?
        person.name = name
        ward_short = (ward.short_name || ward.ward_code).downcase.gsub(/[^a-z]/, '')
        person.email = "councillor#{prabhag_num}.#{ward_short}@mcgm.gov.in"
        person.save!
      elsif person.name != name
        person.update!(name: name)
        corp_updated += 1
      end

      # Attach to ward as corporator
      role = Role.find_or_initialize_by(person: person, roleable: ward, role_name: "corporator")
      if role.new_record?
        role.metadata = { prabhag_number: prabhag_num }
        role.save!
        corp_created += 1
      end
    end

    puts "  Corporators: #{corp_created} created, #{corp_updated} updated, #{corp_skipped} skipped"
    puts "\nTotals: #{Person.count} people, #{Role.count} roles"
  end
end
