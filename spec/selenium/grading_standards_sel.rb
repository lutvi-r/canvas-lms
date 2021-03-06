require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "grading standards selenium tests" do
  it_should_behave_like "in-process server selenium tests"
  
  it "should allow creating/deleting grading standards" do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    e = course_with_teacher :active_course => true,
                            :user => u,
                            :active_enrollment => true
    e.save!
    login_as(username, password)

    get "/courses/#{e.course_id}/grading_standards"
    driver.find_element(:css, ".add_standard_link").click
    standard = driver.find_element(:css, "#grading_standard_new")
    standard.should_not be_nil
    standard.attribute(:class).should match(/editing/)
    standard.find_elements(:css, ".delete_row_link").select(&:displayed?).each_with_index do |link, i|
      if i % 2 == 1
        link.click
        keep_trying_until { !link.displayed? }
      end
    end
    standard.find_element(:css, "input.scheme_name").send_keys("New Standard")
    standard.find_element(:css, ".save_button").click
    keep_trying_until { !standard.attribute(:class).match(/editing/) }
    standard.find_elements(:css, ".grading_standard_row").select(&:displayed?).length.should eql(6)
    standard.find_element(:css, ".standard_title .title").text.should eql("New Standard")
    
    id = standard.attribute(:id)
    standard.find_element(:css, ".delete_grading_standard_link").click
    driver.switch_to.alert.accept
    driver.switch_to.default_content
    keep_trying_until { !(driver.find_element(:css, "##{id}") rescue nil) }
  end
  
  it "should allow setting a grading standard for an assignment" do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    e = course_with_teacher :active_course => true,
                            :user => u,
                            :active_enrollment => true
    e.save!
    login_as(username, password)
    
    @assignment = @course.assignments.create!(:title => "new assignment")
    @standard = @course.grading_standards.create!(:title => "some standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})

    get "/courses/#{e.course_id}/assignments/#{@assignment.id}"
    driver.find_element(:css, ".edit_full_assignment_link").click
    form = driver.find_element(:css, "#edit_assignment_form")
    form.find_element(:css, ".more_options_link").click
    form.find_element(:css, ".grading_type option[value='letter_grade']").select
    form.find_element(:css, ".edit_letter_grades_link").displayed?.should be_true
    form.find_element(:css, ".edit_letter_grades_link").click
    
    dialog = driver.find_element(:css, "#edit_letter_grades_form")
    dialog.find_elements(:css, ".grading_standard_row").select(&:displayed?).length.should eql(12)
    dialog.find_elements(:css, ".grading_standard_row").select(&:displayed?).map{|e| e.find_element(:css, ".name").text }.should eql(["A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "D-", "F"])
    
    dialog.find_element(:css, ".find_grading_standard_link").click
    keep_trying_until { driver.find_element(:css, ".find_grading_standard").attribute(:class).match(/loaded/) }
    dialog.find_element(:css, ".find_grading_standard").displayed?.should be_true
    dialog.find_element(:css, ".display_grading_standard").displayed?.should be_false
    dialog.find_element(:css, ".cancel_find_grading_standard_link").click
    dialog.find_element(:css, ".find_grading_standard").displayed?.should be_false
    dialog.find_element(:css, ".display_grading_standard").displayed?.should be_true
    dialog.find_element(:css, ".find_grading_standard_link").click
    
    dialog.find_elements(:css, ".grading_standard_select .title")[-1].text.should eql(@standard.title)
    dialog.find_elements(:css, ".grading_standard_select")[-1].click
    dialog.find_element(:css, "#grading_standard_brief_#{@standard.id}").displayed?.should be_true
    dialog.find_element(:css, "#grading_standard_brief_#{@standard.id} .select_grading_standard_link").click
    dialog.find_element(:css, "#grading_standard_brief_#{@standard.id}").displayed?.should be_false
    dialog.find_element(:css, ".display_grading_standard").displayed?.should be_true
    dialog.find_element(:css, ".standard_title .title").text.should eql(@standard.title)
    sleep 2
  end
  
  it "should allow setting a grading standard for a course" do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    e = course_with_teacher :active_course => true,
                            :user => u,
                            :active_enrollment => true
    e.save!
    login_as(username, password)
    
    @standard = @course.grading_standards.create!(:title => "some standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})

    get "/courses/#{e.course_id}/details"
    driver.find_element(:css, ".edit_course_link").click
    form = driver.find_element(:css, "#course_form")
    form.find_element(:css, "#course_grading_standard_enabled").click
    form.find_element(:css, "#course_grading_standard_enabled").attribute(:checked).should eql('true')
    
    form.find_element(:css, ".edit_letter_grades_link").displayed?.should be_true
    form.find_element(:css, ".edit_letter_grades_link").click
    
    dialog = driver.find_element(:css, "#edit_letter_grades_form")
    dialog.find_elements(:css, ".grading_standard_row").select(&:displayed?).length.should eql(12)
    dialog.find_elements(:css, ".grading_standard_row").select(&:displayed?).map{|e| e.find_element(:css, ".name").text }.should eql(["A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "D-", "F"])
    
    dialog.find_element(:css, ".find_grading_standard_link").click
    keep_trying_until { driver.find_element(:css, ".find_grading_standard").attribute(:class).match(/loaded/) }
    dialog.find_elements(:css, ".grading_standard_select .title")[-1].text.should eql(@standard.title)
    dialog.find_elements(:css, ".grading_standard_select")[-1].click
    dialog.find_element(:css, "#grading_standard_brief_#{@standard.id}").displayed?.should be_true
    dialog.find_element(:css, "#grading_standard_brief_#{@standard.id} .select_grading_standard_link").click
    dialog.find_element(:css, "#grading_standard_brief_#{@standard.id}").displayed?.should be_false
    dialog.find_element(:css, ".display_grading_standard").displayed?.should be_true
    dialog.find_element(:css, ".standard_title .title").text.should eql(@standard.title)
    
    dialog.find_element(:css, ".remove_grading_standard_link").displayed?.should be_true
    dialog.find_element(:css, ".remove_grading_standard_link").click
    driver.switch_to.alert.accept
    driver.switch_to.default_content
    keep_trying_until { !dialog.displayed? }
    
    form.find_element(:css, "#course_grading_standard_enabled").attribute(:checked).should be_nil
  end
end

describe "grading standards Windows-Firefox-Tests" do
  it_should_behave_like "grading standards selenium tests"
end

