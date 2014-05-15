require 'mechanize'

class Revq

    attr_accessor :issue_count
    attr_accessor :issue_types
    attr_accessor :reqs

    def initialize()
        @issue_count = 0
        @issue_types = Hash.new
        @reqs = Hash.new

        agent = Mechanize.new
        page = agent.get('http://manage.jujucharms.com/tools/review-queue')

        @issue_count = page.search('table').search('tr').count()

        page.search('table').search('tr').each do |row|
            begin
                label = row.search('td').last().text
                if @reqs.length < 5 
                    summary = row.search('td')[3].text.chomp()
                    top_five(summary)
                end
            rescue
                next
            end
            if @issue_types.has_key?("#{label}")  
                @issue_types["#{label}"][:value] += 1
            else  
                @issue_types["#{label}"] = { label: label, value: 1}
            end  
        end
    end

    def top_five(summary)
        return if summary.empty?
        i = @reqs.length
        @reqs[i] = { label: summary, value: nil}
    end

    def truncate_words(s, opts = {})
        opts = {:words => 12}.merge(opts)
        if opts[:sentences]
          return s.split(/\.(\s|$)+/)[0, opts[:sentences]].map{|s| s.strip}.join('. ') + '.'
        end
        a = s.split(/\s/) # or /[ ]+/ to only split on spaces
        n = opts[:words]
        a[0...n].join(' ') + (a.size > n ? '...' : '')
    end

end  


SCHEDULER.every '15m', :first_in => 0 do
  r = Revq.new()
  send_event('review', { items: r.issue_types.values })
  send_event('revqtop5', { items: r.reqs.values })

end