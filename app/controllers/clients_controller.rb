class ClientsController < ApplicationController
  before_action :authenticate_user!

  def index
    @clients = Client.all
  end

  def show
    @client = Client.find(params[:id])
    @projects = current_user.projects.where(projects: { client_id: @client.id })
  end

  def new
    @client = Client.new
  end

  def create
    @client = Client.new(client_params)

    if @client.save
      redirect_to @client
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @client = Client.find(params[:id])
  end

  def update
    @client = Client.find(params[:id])

    if @client.update(client_params)
      redirect_to @client
      flash[:notice] = "client has been updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client = Client.find(params[:id])

    # checks the confirmation field before trying to delete
    if delete_params[:confirmation] == "DELETE"
      if @client.destroy
        flash[:notice] = "Client deleted"
        redirect_to clients_path
      else
        flash[:alert] = "Could not delete client"
        redirect_to edit_client_path(@client)
      end
    else
      flash[:alert] = "Invalid confirmation"
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
end
