Time::DATE_FORMATS[:month_and_year] = "%B %Y"
Time::DATE_FORMATS[:pretty] = lambda { |time| time.strftime("%a, %b %e at %l:%M") + time.strftime("%p").downcase }
Time::DATE_FORMATS[:day] = "%d"
Time::DATE_FORMATS[:mon] = "%m"
Time::DATE_FORMATS[:default] = "%d-%m-%Y"
Time::DATE_FORMATS[:complete] = "%d/%m/%Y às %H:%M"