FROM swiftdocker/swift:4.0

RUN apt-get update && apt-get install -y \
      libpq-dev

# Create build directory
RUN mkdir -p /usr/src
WORKDIR /usr/src

# Add swift source files
ADD Sources Sources/
ADD Tests Tests/

# Add swift Package file
ADD Package.swift .

RUN chmod o+rw -R /usr/lib/swift/CoreFoundation/

RUN swift test
