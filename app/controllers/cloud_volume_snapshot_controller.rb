class CloudVolumeSnapshotController < ApplicationController
  before_action :check_privileges
  before_action :get_session_data
  after_action :cleanup_action
  after_action :set_session_data

  def index
    redirect_to :action => 'show_list'
  end

  # handle buttons pressed on the button bar
  def button
    @edit = session[:edit] # Restore @edit for adv search box
    params[:display] = @display if %w(vms instances images).include?(@display)
    params[:page] = @current_page unless @current_page.nil?   # Save current page for list refresh
    return tag("CloudVolumeSnapshot") if params[:pressed] == 'cloud_volume_snapshot_tag'
    render_button_partial(pfx)
  end

  def show
    @display = params[:display] || "main" unless control_selected?
    @showtype = @display
    @lastaction = "show"

    @snapshot = @record = identify_record(params[:id])
    return if record_no_longer_exists?(@snapshot)

    @gtl_url = "/cloud_volume_snapshot/show/" << @snapshot.id.to_s << "?"
    drop_breadcrumb({:name => "Cloud Volume Snapshots", :url => "/cloud_volume_snapshot/show_list?page=#{@current_page}&refresh=y"}, true)

    case @display
    when "download_pdf", "main", "summary_only"
      get_tagdata(@snapshot)
      drop_breadcrumb(:name => @snapshot.name.to_s + " (Summary)", :url => "/cloud_volume_snapshot/show/#{@snapshot.id}")
      @showtype = "main"
      set_summary_pdf_data if ["download_pdf", "summary_only"].include?(@display)
    when "based_volumes"
      title = ui_lookup(:table => 'based_volumes')
      kls   = CloudVolume
      drop_breadcrumb(:name => @snapshot.name + " (All #{title})", :url => "/cloud_volume_snapshot/show/#{@snapshot.id}?display=based_volumes")
      @view, @pages = get_view(kls, :parent => @snapshot, :association => :based_volumes)
      @showtype = "based_volumes"
      if @view.extras[:total_count] && @view.extras[:auth_count] &&
         @view.extras[:total_count] > @view.extras[:auth_count]
        @bottom_msg = "* You are not authorized to view " + pluralize(@view.extras[:total_count] - @view.extras[:auth_count], "other #{title.singularize}") + " on this " + ui_lookup(:tables => "cloud_volume_snapshot")
      end
    end

    if params[:ppsetting] || params[:searchtag] || params[:entry] || params[:sort_choice]
      replace_gtl_main_div
    end
  end

  # Show the main Cloud Volume Snapshot list view
  def show_list
    @listicon = "cloud_volume_snapshot"
    @lastaction = "show_list"
    process_show_list
  end

  private

  def render_button_partial(pfx)
    if @flash_array && params[:pressed] == "#{@table_name}_delete" && @single_delete
      render :update do |page|
        page.redirect_to :action => 'show_list', :flash_msg => @flash_array[0][:message]
      end
    elsif params[:pshow/"#{pfx}_migrate", "#{pfx}_publish"].include?(params[:pressed])
      render_or_redirect_partial(pfx)
    else
      if @refresh_div == "main_div" && @lastaction == "show_list"
        replace_gtl_main_div
      else
        render_flash
      end
    end
  end

  def get_session_data
    @title      = "Cloud Volume Snapshot"
    @layout     = "cloud_volume_snapshot"
    @lastaction = session[:cloud_volume_snapshot_lastaction]
    @display    = session[:cloud_volume_snapshot_display]
    @filters    = session[:cloud_volume_snapshot_filters]
    @catinfo    = session[:cloud_volume_snapshot_catinfo]
    @showtype   = session[:cloud_volume_snapshot_showtype]
  end

  def set_session_data
    session[:cloud_volume_snapshot_lastaction] = @lastaction
    session[:cloud_volume_snapshot_display]    = @display unless @display.nil?
    session[:cloud_volume_snapshot_filters]    = @filters
    session[:cloud_volume_snapshot_catinfo]    = @catinfo
    session[:cloud_volume_snapshot_showtype]   = @showtype
  end

end
