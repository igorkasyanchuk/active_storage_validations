class RatioModelsController < ApplicationController
  before_action :set_ratio_model, only: [:show, :edit, :update, :destroy]

  # GET /ratio_models
  def index
    @ratio_models = RatioModel.all
  end

  # GET /ratio_models/1
  def show
  end

  # GET /ratio_models/new
  def new
    @ratio_model = RatioModel.new
  end

  # GET /ratio_models/1/edit
  def edit
  end

  # POST /ratio_models
  def create
    @ratio_model = RatioModel.new(ratio_model_params)

    if @ratio_model.save
      redirect_to @ratio_model, notice: 'Ratio model was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /ratio_models/1
  def update
    if @ratio_model.update(ratio_model_params)
      redirect_to @ratio_model, notice: 'Ratio model was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /ratio_models/1
  def destroy
    @ratio_model.destroy
    redirect_to ratio_models_url, notice: 'Ratio model was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ratio_model
      @ratio_model = RatioModel.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def ratio_model_params
      params.require(:ratio_model).permit!
    end
end
