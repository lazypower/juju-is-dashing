require 'github_api'

class GitPulls

    attr_accessor :pulls
    attr_accessor :topics

    def initialize()
        @pulls = 0
        @topics = Hash.new

        g = Github.new oauth_token: ENV['GH_TOKEN']
        issues = g.issues.list(:org => 'juju', :filter => 'all', :auto_pagination => true)
        
        issues.each do |issue|
          if @topics.length < 5
            top_five(issue)
          end
          if issue['pull_request']
              @pulls += 1
          end
        end
    end

    def top_five(issue)
      i = @topics.length
      @topics[i] = {label: issue['title'], value: nil}
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

current_pulls = 0
SCHEDULER.every '5m', :first_in => 0 do
  g = GitPulls.new

  last_pulls = current_pulls
  current_pulls = g.pulls

  send_event('github', { current: current_pulls, last: last_pulls })
  send_event('ghtop5', { items: g.topics.values })
end
