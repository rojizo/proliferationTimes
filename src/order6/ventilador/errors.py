"""
Errors and descriptions
"""

__author__ = 'Alvaro Lozano Rojo'

# Error codes
ERROR_UNKNOWN_TASK    = {'err_id': 1, 'err_description': "The task ID was not found on the DB."}
ERROR_UNKNOWN_REQUEST = {'err_id': 2, 'err_description': "I don't know what to do with that request."}
ERROR_TASK_OVERDUE    = {'err_id': 3, 'err_description': "The task is overdue..."}
ERROR_NONDICT_REQUEST = {'err_id': 4, 'err_description': "The sent message is not a dict"}
ERROR_NO_TASK         = {'err_id': 5, 'err_description': "There is no task"}
