import { Injectable } from '@angular/core'
import { formatDate } from '@angular/common'
import { HttpClient, HttpParams } from '@angular/common/http'
import { Observable, of } from 'rxjs'
import { catchError, tap } from 'rxjs/operators'

import {
  WorkflowQueryParams,
  WorkflowPage,
  WorkflowData,
  WorkflowHistory,
} from '../models/page/workflow_page'
import { Workflow, WorkflowEvent } from '../models/workflow'
import { StartWorkflowDefinition } from '../models/startWorkflowDefinition'

@Injectable()
export class WorkflowService {
  private workflowUrl = '/api/workflow'
  private workflowsUrl = '/api/step_flow/workflows'
  private workflowFiltersUrl = 'api/worfklow_filters'
  private workflowDefinitionsUrl = '/api/step_flow/definitions'
  private statisticsUrl = '/api/step_flow/workflows_statistics'
  private statusUrl = '/api/step_flow/workflows_status'

  constructor(private http: HttpClient) {}

  getWorkflowDefinitions(
    page?: number,
    per_page?: number,
    right_action?: string,
    search?: string,
    versions?: string[],
    mode?: string,
  ): Observable<WorkflowPage> {
    let params = new HttpParams()
    if (per_page) {
      params = params.append('size', per_page.toString())
    }
    if (page > 0) {
      params = params.append('page', String(page))
    }
    if (right_action) {
      params = params.append('right_action', right_action)
    }
    if (search) {
      params = params.append('search', search)
    }
    if (versions) {
      for (const version of versions) {
        params = params.append('versions[]', version)
      }
    }
    if (mode) {
      params = params.append('mode', mode)
    }
    return this.http
      .get<WorkflowPage>(this.workflowDefinitionsUrl, { params: params })
      .pipe(
        tap((_workflowPage) => this.log('fetched WorkflowPage')),
        catchError(this.handleError('getWorkflowDefinitions', undefined)),
      )
  }

  getWorkflows(
    page: number,
    per_page: number,
    parameters: WorkflowQueryParams,
  ): Observable<WorkflowPage> {
    let params = new HttpParams()

    if (per_page) {
      params = params.append('size', per_page.toString())
    }
    if (page > 0) {
      params = params.append('page', String(page))
    }
    for (const identifier of parameters.identifiers) {
      params = params.append('workflow_ids[]', identifier)
    }
    for (const state of parameters.status) {
      params = params.append('states[]', state)
    }
    if (parameters.mode.length == 1) {
      if (parameters.mode[0] == 'live') {
        params = params.append('is_live', 'true')
      } else params = params.append('is_live', 'false')
    }
    if (parameters.search) {
      params = params.append('search', parameters.search)
    }
    params = params.append(
      'after_date',
      formatDate(
        parameters.selectedDateRange.startDate,
        'yyyy-MM-ddTHH:mm:ss',
        'fr',
      ),
    )
    params = params.append(
      'before_date',
      formatDate(
        parameters.selectedDateRange.endDate,
        'yyyy-MM-ddTHH:mm:ss',
        'fr',
      ),
    )

    return this.http
      .get<WorkflowPage>(this.workflowsUrl, { params: params })
      .pipe(
        tap((_workflowPage) => this.log('fetched WorkflowPage')),
        catchError(this.handleError('getWorkflows', undefined)),
      )
  }

  getWorkflowDefinition(
    workflow_identifier: string,
    reference: string,
  ): Observable<Workflow> {
    let params = new HttpParams()
    params = params.append('reference', reference)

    return this.http
      .get<Workflow>(this.workflowUrl + '/' + workflow_identifier, {
        params: params,
      })
      .pipe(
        tap((_workflowPage) => this.log('fetched Workflow')),
        catchError(this.handleError('getWorkflowDefinition', undefined)),
      )
  }

  getWorkflow(workflow_id: number): Observable<WorkflowData> {
    return this.http
      .get<WorkflowData>(this.workflowsUrl + '/' + workflow_id.toString())
      .pipe(
        tap((_workflowPage) => this.log('fetched Workflow')),
        catchError(this.handleError('getWorkflow', undefined)),
      )
  }

  getWorkflowForJob(job_id: number, mode: string): Observable<WorkflowData> {
    let params = new HttpParams()
    params = params.append('job_id', job_id.toString())
    params = params.append('mode', mode)

    return this.http
      .get<WorkflowData>(this.workflowsUrl, { params: params })
      .pipe(
        tap((_workflowPage) => this.log('fetched Workflow')),
        catchError(this.handleError('getWorkflow', undefined)),
      )
  }

  createWorkflow(
    startWorkflowDefinition: StartWorkflowDefinition,
  ): Observable<WorkflowData> {
    return this.http
      .post<WorkflowData>(this.workflowsUrl, startWorkflowDefinition)
      .pipe(
        tap((_workflowPage) => this.log('fetched Workflow')),
        catchError(this.handleError('createWorkflow', undefined)),
      )
  }

  getCreateWorkflowParameters(workflow: Workflow): StartWorkflowDefinition {
    const parameters = workflow.parameters.reduce(function (map, parameter) {
      const value = parseInt(parameter.value)
      console.log(value)
      if (isNaN(value)) {
        map[parameter.id] = parameter.value
      } else {
        map[parameter.id] = value
      }
      return map
    }, {})
    const create_workflow_parameters = new StartWorkflowDefinition()
    create_workflow_parameters.workflow_identifier = workflow.identifier
    create_workflow_parameters.parameters = parameters
    create_workflow_parameters.reference = workflow.reference
    create_workflow_parameters.version_major = parseInt(workflow.version_major)
    create_workflow_parameters.version_minor = parseInt(workflow.version_minor)
    create_workflow_parameters.version_micro = parseInt(workflow.version_micro)

    return create_workflow_parameters
  }

  sendWorkflowEvent(
    workflow_id: number,
    event: WorkflowEvent,
  ): Observable<Workflow> {
    return this.http
      .post<Workflow>(this.workflowsUrl + '/' + workflow_id + '/events', event)
      .pipe(
        tap((_workflowPage) => this.log(event.event + ' Workflow')),
        catchError(this.handleError('abortWorkflow', undefined)),
      )
  }

  getWorkflowStatistics(
    parameters: WorkflowQueryParams,
  ): Observable<WorkflowHistory> {
    let params = new HttpParams()

    for (const identifier of parameters.identifiers) {
      params = params.append('identifiers[]', identifier)
    }
    params = params.append('time_interval', parameters.time_interval.toString())

    if (parameters.mode.length == 1) {
      if (parameters.mode[0] == 'live') {
        params = params.append('is_live', 'true')
      } else params = params.append('is_live', 'false')
    }
    params = params.append(
      'start_date',
      parameters.selectedDateRange.startDate.toISOString(),
    )
    params = params.append(
      'end_date',
      parameters.selectedDateRange.endDate.toISOString(),
    )

    return this.http.get<Workflow>(this.statisticsUrl, { params: params }).pipe(
      tap((_workflowPage) => this.log('statistics Workflow')),
      catchError(this.handleError('getWorkflowStatistics', undefined)),
    )
  }

  getWorkflowStatus(): Observable<Array<string>> {
    return this.http.get<Array<string>>(this.statusUrl).pipe(
      tap((_workflowPage) => this.log('fetched Workflow Status')),
      catchError(this.handleError('getWorkflowStatus', undefined)),
    )
  }

  private handleError<T>(operation = 'operation', result?: T) {
    return (error: any): Observable<T> => {
      this.log(`${operation} failed: ${error.message}`)
      return of(result as T)
    }
  }

  private log(message: string) {
    console.log('WorkflowService: ' + message)
  }
}
