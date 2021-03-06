class ShowTracker
  def initialize(api)
    @api = api
  end

  def track_show(user, show, seen_all = false)
    return if user.shows.include? show

    user.shows << show
    
    add_all_episodes(user, show, seen_all)

    user.save
  end

  def find_or_create_show(show_title)
    result = @api.search(show_title).first
    # if result is nil, we didn't find the show and shit is gonna explode

    show = Show.where(:slug => result["tvdb_id"]).first

    if show.nil?
      show = Show.create(:name => result["title"], 
                         :slug => result["tvdb_id"])
      create_aired_episodes(show)
    end

    show
  end

  private
  def add_all_episodes(user, show, seen_all)
    show.episodes.each do |episode|
      user.user_watches << UserWatch.create(:user => user, 
                                            :episode => episode, 
                                            :watched => seen_all)
    end
  end

  def create_aired_episodes(show)
    episode_result = @api.all_aired_episodes(show)

    episode_result.each do |result|
      next if result["first_aired"] == 0 
      show.episodes << Episode.create(:name => result["title"], 
                                      :season_number => result["season"],
                                      :episode_number => result["episode"],
                                      :air_date => Time.at(result["first_aired"]))
    end
  end
end