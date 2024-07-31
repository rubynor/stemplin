class LandingPageController < ApplicationController
  def index
    @services = services
    @testimonials = testimonials
    @getting_started_steps = getting_started_steps
  end

  private

  # @Note: Keeping these static landing pages content until i find a better place
  def services
    [
      {
        title: "Easy time logging",
        identifier: "easy-time-logging",
        description: "Team members effortlessly record work hours on various tasks, ensuring every minute is tracked accurately and efficiently across multiple projects and activities.",
        illustration: "easy-time-logging.svg"
      },
      {
        title: "Easy billing",
        identifier: "easy-billing",
        description: "Managers can easily send invoices to clients based on registered time, and include comprehensive time reports, ensuring transparency and customer satisfaction.",
        illustration: "full-visibility.svg"
      },
      {
        title: "Workspace administration",
        identifier: "workspace-administration",
        description: "Easily manage and onboard team members with your workspace, ensuring seamless and effective collaboration on all tasks.",
        illustration: "workspace-administration.svg"
      },
      {
        title: "Comprehensive insights",
        identifier: "comprehensive-insights",
        description: "Time tracking provides managers with detailed insights into activities and time allocations across all projects. The data is presented in comprehensive reports that can be leveraged to improve efficiency and productivity.",
        illustration: "performance-tracking.svg"
      }
    ]
  end

  # @Note: Keeping these static landing pages content until i find a better place
  def testimonials
    [
      {
        first_name: "John",
        last_name: "Doe",
        quote: lorem_ipsum,
        role: "Devops Engineer"
      },
      {
        first_name: "Marty",
        last_name: "Harper",
        quote: lorem_ipsum,
        role: "QA Engineer"
      },
      {
        first_name: "Robert",
        last_name: "Henn",
        quote: lorem_ipsum,
        role: "Product Owner"
      },
      {
        first_name: "Jack",
        last_name: "Doe",
        quote: lorem_ipsum,
        role: "Devops Engineer"
      }
    ]
  end

  def lorem_ipsum
    "lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation."
  end

  def getting_started_steps
    [ "Sign up", "Create a project", "Invite your team", "Start tracking time" ]
  end
end
