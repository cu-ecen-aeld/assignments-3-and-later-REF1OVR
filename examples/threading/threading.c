#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param){
	/*
	 * TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
	 * hint: use a cast like the one below to obtain thread arguments from your parameter
	 * struct thread_data* thread_func_args = (struct thread_data *) thread_param;
	 */
	struct thread_data* thread_func_args = (struct thread_data *) thread_param;

	DEBUG_LOG("Thread starting. Waiting %d ms before obtaining mutex", thread_func_args->wait_to_obtain_ms);

	// Wait before trying to obtain the mutex
	usleep(thread_func_args->wait_to_obtain_ms * 1000);

	DEBUG_LOG("Trying to obtain mutex");

	// Check for errors and set thread_complete_success accordingly
	bool success = true; // Assume success initially

	// Obtain the mutex
	int err = pthread_mutex_lock(thread_func_args->mutex);
	if(err != 0){
		ERROR_LOG("Failed to lock mutex");
		success = false;
	}

	DEBUG_LOG("Mutex obtained. Waiting %d ms before releasing mutex", thread_func_args->wait_to_release_ms);

	// Wait before releasing the mutex
	usleep(thread_func_args->wait_to_release_ms * 1000);

	DEBUG_LOG("Releasing mutex");

	// Release the mutex
	err = pthread_mutex_unlock(thread_func_args->mutex);
	if(err != 0){
		ERROR_LOG("Failed to unlock mutex");
		success = false;
	}

	// Set thread_complete_success based on the execution status
	thread_func_args->thread_complete_success = success;

	// Return the thread_data pointer
	return thread_func_args;
}

bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex, int wait_to_obtain_ms, int wait_to_release_ms){
	/*
	 * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
	 * using threadfunc() as entry point.
	 *
	 * return true if successful.
	 *
	 * See implementation details in threading.h file comment block
	 */
	DEBUG_LOG("Starting a new thread with wait_to_obtain_ms = %d and wait_to_release_ms = %d", wait_to_obtain_ms, wait_to_release_ms);

	// Allocate memory for thread_data
	struct thread_data *thread_func_args = malloc(sizeof(struct thread_data));
	if(!thread_func_args){
		ERROR_LOG("Failed to allocate memory for thread data");
		return false;
	}

	// Set up the mutex and wait arguments
	thread_func_args->mutex = mutex;
	thread_func_args->wait_to_obtain_ms = wait_to_obtain_ms;
	thread_func_args->wait_to_release_ms = wait_to_release_ms;

	// Create the thread
	int err = pthread_create(thread, NULL, threadfunc, (void *)thread_func_args);
	if(err != 0){
		ERROR_LOG("Failed to create thread");
		free(thread_func_args);		// Free the memory if thread creation fails
		return false;
	}

	DEBUG_LOG("Thread created successfully");

	return true;
}
