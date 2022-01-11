
import {Component, ViewChild} from '@angular/core'
import {MatCheckboxModule} from '@angular/material/checkbox'
import {PageEvent} from '@angular/material/paginator'
import {ActivatedRoute, Router} from '@angular/router'
import {MatDialog} from '@angular/material/dialog'

import {UserService} from '../services/user.service'
import {UserPage, RolePage} from '../models/page/user_page'
import {User, Role, Right, RoleEvent, RoleEventAction} from '../models/user'
import {RoleOrRightDeletionDialogComponent} from './dialogs/role_or_right_deletion_dialog.component'
import {UserShowCredentialsDialogComponent} from './dialogs/user_show_credentials_dialog.component'

@Component({
  selector: 'users-component',
  templateUrl: 'users.component.html',
  styleUrls: ['./users.component.less'],
})

export class UsersComponent {
  length = 1000
  pageSizeOptions = [
    20,
    50,
    100
  ]
  pageSize = this.pageSizeOptions[0];
  email: string
  password: string
  user_error_message: string
  page = 0
  sub = undefined

  pageEvent: PageEvent
  users: UserPage

  roles: RolePage
  all_roles: RolePage
  rights: Right[] = []
  available_permissions: string[]
  already_set_entity: string[] = []
  new_role_name: string
  role_error_message: string

  constructor(
    private userService: UserService,
    private route: ActivatedRoute,
    private router: Router,
    private dialog: MatDialog,
  ) {}

  ngOnInit() {
    this.sub = this.route
      .queryParams
      .subscribe(params => {
        this.page = +params['page'] || 0
        this.getUsers(this.page)
        this.getRoles(this.page)
        this.getAllRoles()
      })
  }

  ngOnDestroy() {
    this.sub.unsubscribe()
  }

  getUsers(index): void {
    this.userService.getUsers(index, this.pageSize)
    .subscribe(userPage => {
      this.users = userPage
      if (userPage) {
        this.length = userPage.total
      } else {
        this.length = 0
      }
    })
  }

  getRoles(index): void {
    this.userService.getRoles(index, this.pageSize)
      .subscribe(roles => {
        this.roles = roles;
        for(let role of this.roles.data) {
          role.rights.forEach((right) => this.rights.push(right));
        }
      });
    this.userService.getRightDefinitions()
    .subscribe(rightDefinitions => {
        this.available_permissions = rightDefinitions.rights;
      });
  }

  getAllRoles(): void {
    this.userService.getAllRoles()
      .subscribe(roles => {
        this.all_roles = roles;
      });
  }

  eventGetUsers(event): void {
    this.router.navigate(['/users'], { queryParams: this.getQueryParamsForPage(event.pageIndex) })
    this.getUsers(event.pageIndex)
  }

  eventGetRoles(event): void {
    this.getRoles(this.page);
  }

  inviteUser(): void {
    this.user_error_message = ''
    this.userService.inviteUser(this.email)
    .subscribe(response => {
      if (response === undefined) {
        this.user_error_message = 'Unable to create user'
      } else {
        this.email = ''
        this.password = ''
      }
      this.getUsers(0)
    })
  }

  generateCredentials(user): void {
    this.userService.generateCredentials(user)
    .subscribe(response_user => {
      let dialogRef = this.dialog.open(UserShowCredentialsDialogComponent, {data: {
        'user': response_user
      }})

      dialogRef.afterClosed().subscribe(response => {
        this.getUsers(this.page)
      })
    })
  }

  removeUser(user_id): void {
    this.userService.removeUser(user_id)
    .subscribe(response => {
      this.getUsers(this.page)
    })
  }

  getQueryParamsForPage(pageIndex: number): Object {
    var params = {}
    if (pageIndex !== 0) {
      params['page'] = pageIndex
    }
    return params
  }

  createRole() {
    let role = new Role(this.new_role_name);
    this.role_error_message = '';
    this.userService.createRole(role).subscribe(role => {
      if(!role) {
        this.role_error_message = "Unable to create role";
      }
      this.getRoles(this.page);
    });
  }

  roleHasChanged(event: RoleEvent) {

    if (event.action == RoleEventAction.Update) {
      this.userService.updateRole(event.role).subscribe(role => {
        // console.log("Updated role:", role);
        this.getRoles(this.page);
      });
    }

    if (event.action == RoleEventAction.Delete) {
      // Ask for confirmation
      let dialogRef = this.dialog.open(RoleOrRightDeletionDialogComponent, {data: {
        'role': event.role
      }})

      dialogRef.afterClosed().subscribe(response => {
        if(response) {
          this.userService.deleteRole(event.role).subscribe(role => {
            // console.log("Deleted role:", role);
            this.userService.deleteUsersRole(event.role).subscribe(updatedUsers => {
              // console.log("Updated role users:", updatedUsers);
              this.getUsers(this.page);
            })
            this.getRoles(this.page);
          });
        }
      })
    }

  }
}
