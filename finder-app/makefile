# Compiler settings
CC := gcc
ifeq ($(CROSS_COMPILE), aarch64-none-linux-gnu-)
    CC := $(CROSS_COMPILE)gcc
endif

# Extra options for compiler
CFLAGS=-Wall

# Target settings
TARGET := writer
SRCS := writer.c
OBJS := $(SRCS:.c=.o)

# Default target
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(INCLUDES) $(OBJS) -o $(TARGET) $(LDFLAGS)

# Clean target
clean:
	rm -f $(TARGET) $(OBJS)
