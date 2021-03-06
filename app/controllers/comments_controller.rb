class CommentsController < ApplicationController

  before_filter :require_user, only: [:new, :create, :edit, :update, :destroy]
  before_filter :setup

  def create
    @comment = Comment.new(params[:comment])
    @comment.user = current_user
    @comment.commentable = @commentable
    @comment.ip_address = request.remote_addr

    if @comment.save
      flash[:notice] = "Succesfully posted."
    else
      flash[:error] = "Failed to save your comment: #{@comment.errors.map(&:to_s)}"
      # TODO should render the 'new' template
    end
    # redirect_back_or_default(url_for(@commentable))
    redirect_to(url_for(@commentable))
  end

  def edit
    render text: "TODO", status: 420
  end

  def update
    render text: "TODO", status: 420
  end

  def destroy
    raise NoPermissionError unless is_admin? || @comment.user == current_user
    @comment.hidden_at = Time.now
    @comment.save!
    flash[:notice] = "Comment deleted"
    redirect_back_or_default(comments_path(@commentable))
  end


  protected

  def setup
    # Find a specific Comment objects
    if params[:id]
      @comment = Comment.find(params[:id])
    end

    # Found a foreign key for an object we happen to be commenting on
    if params[:tag_id]
      @commentable = Tag.find(params[:tag_id])
    elsif params[:user_id]
      @commentable = User.find_by_param(params[:user_id])
    else
      raise ActiveRecord::RecordNotFound, "A commentable (parent) object is required"
    end
  end

end
