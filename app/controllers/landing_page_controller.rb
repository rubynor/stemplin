class LandingPageController < ApplicationController
  def index
    @services = services
  end

  private

  def services
    [
      {
        title: "Easy time logging",
        identifier: "easy-time-logging",
        description: "Team members effortlessly record work hours on various tasks, ensuring every minute is tracked accurately and efficiently across multiple projects and activities.",
        illustration: "easy-time-logging.svg"
      },
      {
        title: "Full visibility",
        identifier: "full-visibility",
        description: "Detailed insight into team activities and durations across all projects, providing comprehensive reports that highlight individual contributions and overall team performance.",
        illustration: "full-visibility.svg"
      },
      {
        title: "Workspace administration",
        identifier: "workspace-administration",
        description: "Easily manage and onboard team members within your workspace, ensuring seamless integration and effective collaboration on all tasks.",
        illustration: "workspace-administration.svg"
      },
      {
        title: "Performance tracking",
        identifier: "performance-tracking",
        description: "Monitor productivity and identify areas for efficiency improvement, leveraging data analytics to pinpoint bottlenecks and optimize workflow processes for better outcomes.",
        illustration: "performance-tracking.svg"
      }
    ]
  end
end
