defmodule ExSubtilBackend.Workflow.Step.HttpDownload do

  alias ExSubtilBackend.Jobs
  alias ExSubtilBackend.Amqp.JobHttpEmitter

  def launch(workflow) do
    ExVideoFactory.get_http_url_for_ttml(workflow.reference)
    |> start_download_via_http(workflow)
  end


  defp start_download_via_http([], _workflow), do: {:ok, "started"}
  defp start_download_via_http([url | urls], workflow) do
    filename = Path.basename(url)

    job_params = %{
      name: "download_http",
      workflow_id: workflow.id,
      params: %{
        source: %{
          path: url
        },
        destination: %{
          path: "/tmp/ftp_ftv/" <> workflow.reference <> "/" <> filename
        }
      }
    }

    {:ok, job} = Jobs.create_job(job_params)
    params = %{
      job_id: job.id,
      parameters: job.params
    }
    JobHttpEmitter.publish_json(params)
    start_download_via_http(urls, workflow)
  end
end
