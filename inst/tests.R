devtools::load_all()

tests <- c("https://www.oie.int/wahis_2/public/wahid.php/Reviewreport/semestrial/review?year=2008&semester=2&wild=0&country=LCA&this_country_code=LCA&detailed=1",
            "https://www.oie.int/wahis_2/public/wahid.php/Reviewreport/semestrial/review?year=2016&semester=1&wild=0&country=TON&this_country_code=TON&detailed=1",
            "https://www.oie.int/wahis_2/public/wahid.php/Reviewreport/semestrial/review?year=2013&semester=0&wild=0&country=ATG&this_country_code=ATG&detailed=1",
            "https://www.oie.int/wahis_2/public/wahid.php/Reviewreport/semestrial/review?year=2011&semester=0&wild=0&country=TZA&this_country_code=TZA&detailed=1",
            "https://www.oie.int/wahis_2/public/wahid.php/Reviewreport/semestrial/review?year=2009&semester=1&wild=0&country=HRV&this_country_code=HRV&detailed=1",
            "https://www.oie.int/wahis_2/public/wahid.php/Reviewreport/semestrial/review?year=2019&semester=1&wild=0&country=TUR&this_country_code=TUR&detailed=1",
            "https://www.oie.int/wahis_2/public/wahid.php/Reviewreport/semestrial/review?year=2012&semester=2&wild=0&country=AZE&this_country_code=AZE&detailed=1",
            "https://www.oie.int/wahis_2/public/wahid.php/Reviewreport/semestrial/review?year=2009&semester=2&wild=0&country=KHM&this_country_code=KHM&detailed=1",
            "https://www.oie.int/wahis_2/public/wahid.php/Reviewreport/semestrial/review?year=2018&semester=1&wild=0&country=KHM&this_country_code=KHM&detailed=1",
            "https://www.oie.int/wahis_2/public/wahid.php/Reviewreport/semestrial/review?year=2013&semester=2&wild=0&country=SYR&this_country_code=SYR&detailed=1")

z <- map_curl(tests, .retry = 5, .logfile = "out.txt",
              .handle_opts = list(low_speed_limit = 100, low_speed_time = 10))

