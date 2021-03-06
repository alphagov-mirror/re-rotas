class TeamsController < ApplicationController
  def index
    @teams = Team.all
  end

  def new
    @team = Team.new
    @org_units = OrgUnit.all
  end

  def edit
    @team = Team.friendly.find(params[:id])
    @org_units = OrgUnit.all
  end

  def create
    @team = Team.new(params.permit(:name, :description, :org_unit_id))

    unless @team.valid?
      @org_units = OrgUnit.all
      return render :new
    end

    @team.save
    redirect_to team_path(@team)
  end

  def update
    @team = Team.friendly.find(params[:id])
    @team.assign_attributes(params.permit(:name, :description, :org_unit_id))

    unless @team.valid?
      @org_units = OrgUnit.all
      return render :edit
    end

    @team.save
    redirect_to team_path(@team)
  end

  def show
    @team = Team.friendly.find(params[:id])

    @events_by_calendar = {}
    @desc = Rotas::MarkdownRenderer.render(@team.description || '')

    @team.calendars.each do |calendar|
      events = calendar.person_day_events

      events.group_by(&:date).each do |date, cal_events|
        @events_by_calendar[date] ||= {}
        @events_by_calendar[date][calendar] = cal_events
      end
    end

    @team_members = @team.members

    unless params[:all]
      @events_by_calendar = @events_by_calendar.reject do |d, _|
        d < Date.today
      end
    end

    @team_members = @team_members.uniq
  end

  def conflicts
    @team               = Team.friendly.find(params[:id])
    annual_leave_events = AnnualLeaveEvent.all
    calendars           = @team.calendars

    @conflicts = Rotas::Conflicts.find(
      annual_leave_events,
      calendars.map { |c| [c, c.person_day_events.group_by(&:date)] }
    ).reject { |_, c| c.empty? }
  end
end
