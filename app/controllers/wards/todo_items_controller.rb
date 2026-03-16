module Wards
  class TodoItemsController < ApplicationController
    before_action :set_ward
    before_action :set_issue

    def create
      @todo_item = @issue.todo_items.build(todo_item_params)
      @todo_item.position = @issue.todo_items.count + 1

      if @todo_item.save
        redirect_to ward_issue_path(@ward, @issue), notice: "Todo added."
      else
        redirect_to ward_issue_path(@ward, @issue), alert: "Could not add todo."
      end
    end

    def toggle
      @todo_item = @issue.todo_items.find(params[:id])
      @todo_item.toggle!
      redirect_to ward_issue_path(@ward, @issue)
    end

    private

    def set_ward
      @ward = Ward.all.find { |w| w.to_param == params[:ward_id] } || Ward.find_by!(ward_code: params[:ward_id].upcase)
    end

    def set_issue
      @issue = @ward.issues.find(params[:issue_id])
    end

    def todo_item_params
      params.require(:todo_item).permit(:title)
    end
  end
end
