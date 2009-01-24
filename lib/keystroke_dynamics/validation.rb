# == Summary
# The Validation class is used to:
# * validate username, password and keyboard metric
# * enroll new users with username, password and averaged keyboard metric
# * house the cryptographic functions needed for these operations

require 'fileutils'
require 'digest/sha1'
require 'openssl'
require 'base64'

# Module housing Analysis class, Validation class and associated constants
module KeystrokeDynamics

# Password hashes file.
PH_FILE = File.join(File.dirname(__FILE__), "../passwd")

# Keystrokes dynamics dir.
KSD_DIR = File.join(File.dirname(__FILE__), "../keystroke_dynamics")

# An accuracy threshold of 0 allows for maximum deviation from measured mean/min/max seek and hold times.
# An accuracy threshold of 0.5 allows for half of total deviation from measured mean/min/max seek and hold times.
# An accuracy threshold of 1 allows for 0 milliseconds of total deviation from measured mean/min/max seek and hold times.
ACCURACY_THRESHOLD = 0.5

# == Summary
# The Validation class is used to:
# * validate username, password and keyboard metric
# * enroll new users with username, password and averaged keyboard metric
# * house the cryptographic functions needed for these operations
#
# === Keying scheme
# The password file houses a salted password hash and the salt generated for each user that has enrolled. The unsalted password hash, plus the salt (which is actually an AES IV) is used for encrypting and decrypting the keyboard metrics analyzed during enrollment and validation.
#
# == Notes
# All these methods are class methods. In other languages you could call this a static class.
class Validation

  # Validates login details accompanied by an array of keystroke arrays
  # (Usually this would be an array with just one keystroke array, but I made it like this to be able to support more elaborate authentication mechanisms with longer texts and more input fields. it might be beneficial to have more data validated at a higher threshold to even out deviation.)
  # When a user tries to validate, the user's salted password hash and iv (the salt) are loaded from the reference metric file created at enrollment. These are used to compare the user's login credentials as would normally happen. After that the metric acquired during login is compared to the reference metric for the user, which is decrypted from the disk using the unsalted password hash as a key.
  # Returns a boolean:
  # Returns false if a login error occurs.
  # Returns true only if login information is correct and keystroke dynamics match the profile saved at enrollment within limit defined by MAX_ALLOWED_DEVIATION.
  def self.validate(username, password, keystroke_array_array)
    pass_hashes = self.load_pass_hashes
    unless pass_hashes[username.to_sym].nil?
      iv = pass_hashes[username.to_sym][:iv]
    else
      iv = ""
    end
    # Match login details in password file
    if (pass_hashes[username.to_sym] || {})[:hash] == self.pass_hash(password,iv)
      # Open user's reference metric
      begin
        mean_metric = File.open(File.join(KSD_DIR,"#{username}.met"), 'rb') do |f|
          Marshal.load(self.decrypt(f.read, password, iv))
        end
      rescue
        mean_metric = []
        puts "Keystroke dynamics not registered for user #{username}"
        return false
      end
      # Compare metrics for known characters
      mean_accuracy = Analysis.compare_metrics(Analysis.metric(keystroke_array_array), mean_metric)
      # ACCURACY_THRESHOLD allows weighting of the allowed deviation.
      # For example, if MAX_ALLOWED_DEVIATION is 1000 ms, setting ACCURACY_THRESHOLD to 0.5 would allow deviations of no more than 500 ms.
      if mean_accuracy < ACCURACY_THRESHOLD
        puts "Keystroke dynamics didn't match user #{username} (measuered mean accuracy: #{mean_accuracy}, required mean accuracy: > #{ACCURACY_THRESHOLD})"
        return false
      else
        puts "Verified user #{username} with mean accuracy of #{mean_accuracy}"
        return true
      end
    elsif pass_hashes[username.to_sym].is_a?(Hash)
      puts "Incorrect password for user #{username}"
      return false
    else
      puts "User \"#{username}\" not enrolled"
      return false
    end
  end

  # Enrolls a user.
  # When a user tries to enroll and no such user exists in the password file, a new entry in the password file is created. The entry contains a salted password hash and the salt which double respectively as they key and intialization vector (IV) for cryptographic operations on the user's keystroke metric.
  # An average of the supplied 2 dimensional array is calculated, which is encrypted and written to a file to be used as a reference metric.
  # Returns a boolean
  # Returns false if a user with the supplied username is already enrolled.
  # Returns true if everything went as planned, returns false if username or password are empty or a user by the same name exists.
  def self.enroll(username, password, keystroke_array_array)
    pass_hashes = self.load_pass_hashes
    if username == ""
      puts "Username can't be blank"
      return false
    end
    if password == ""
      puts "Password can't be blank"
      return false
    end
    if pass_hashes[username.to_sym] != nil
      puts "User exists"
      return false
    end
    iv = OpenSSL::Cipher::Cipher.new("aes-256-cbc").random_iv
    pass_hashes[username.to_sym] = {:hash => self.pass_hash(password,iv), :iv => iv}
    self.create_met_dir
    # Saves encrypted metric to file
    File.open(File.join(KSD_DIR,"#{username}.met"), 'wb') do |f|
      marshal = Marshal.dump(Analysis.metric(keystroke_array_array))
      f.write(self.encrypt(marshal, password, pass_hashes[username.to_sym][:iv]))
    end
    self.save_pass_hashes(pass_hashes)
    return true
  end

  # Returns SHA1 hash of optionally salted string.
  def self.pass_hash(pass, salt = "")
    Digest::SHA1.hexdigest(pass+salt)
  end

  # Returns Base64 encoded, AES 256 encrypted string using hashed key.
  def self.encrypt(string, key, iv)
    c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    c.encrypt
    # it is very important to not use a salted hash here, because that is written to the passwords file
    c.key = self.pass_hash(key)
    c.iv = iv
    e = c.update(Base64.encode64(string))
    e << c.final
    e
  end

  # Returns AES 256 decrypted, Base64 decoded string using hashed key.
  def self.decrypt(string, key, iv)
    c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    c.decrypt
    c.key = self.pass_hash(key)
    c.iv = iv
    d = c.update(string)
    d << c.final
    Base64.decode64(d)
  end

  # Loads usernames, salted password hashes and ivs.
  # Returns a hash of login information loaded from disk.
  # Returned hash takes the form of <tt>{username.to_sym => {:hash, :iv }</tt>.
  def self.load_pass_hashes
    unless File.exists?(PH_FILE)
      FileUtils.touch(PH_FILE)
      File.open(PH_FILE,'wb') {|f| Marshal.dump({}, f)}
    end
    File.open(PH_FILE, 'rb') { |f| Marshal.load(f)} || {}
  end

  # Writes the login information information to disk.
  def self.save_pass_hashes(pass_hashes)
    File.open(PH_FILE, 'wb') { |f| Marshal.dump(pass_hashes, f)}
  end

  # Creates a directory for encrypted metric files if it doenst exist yet.
  def self.create_met_dir
    FileUtils.mkdir(KSD_DIR) unless File.exists?(KSD_DIR)
  end

end

end
