class TransactionsController < ApplicationController
  def index
    require_admin!
    @transactions   = Transaction.all
    @transactions_paginated = Kaminari.paginate_array(@transactions).page(params[:transactions_page]).per(100)
  end

  def destroy
  	require_admin!
  	Transaction.destroy(params[:id])
    redirect_to :back, :notice => 'Transaction was deleted.'
  end
end