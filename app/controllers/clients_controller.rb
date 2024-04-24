class ClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_client, only: %i[ show edit destroy ]

  def index
    @clients = authorized_scope(Client, type: :relation).all
    authorize! @clients
  end

  def show
    @projects = authorized_scope(Project, type: :relation).where(projects: { client_id: @client.id })
  end

  def new
    @client = authorized_scope(Client, type: :relation).new
    authorize! @client
  end

  def create
    @client = authorized_scope(Client, type: :relation).new(client_params)
    authorize! @client

    if @client.save
      redirect_to @client
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @client.update(client_params)
      redirect_to @client
      flash[:notice] = t('notice.client_has_been_updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # checks the confirmation field before trying to delete
    if delete_params[:confirmation] == "DELETE"
      if @client.destroy
        flash[:notice] = t('notice.client_deleted')
        redirect_to clients_path
      else
        flash[:alert] = t('alert.could_not_delete_client')
        redirect_to edit_client_path(@client)
      end
    else
      flash[:alert] = t('alert.invalid_confirmation')
      redirect_to edit_client_path(@client)
    end
  end

  private

  def client_params
    params.require(:client).permit(:name, :description)
  end

  def delete_params
    params.permit(:confirmation, :id)
  end

  def set_client
    @client = Client.find(params[:id])
    authorize! @client
  end
end
