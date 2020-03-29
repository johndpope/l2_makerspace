# This node handles ROS-side logic for the VR server
from l2_msgs.srv import GetFile, SpawnObject3D, GetObject3D
from l2_msgs.msg import Object3DArray, Object3D
from gazebo_msgs.msg import ModelStates
from std_msgs.msg import String
import pprint
import rclpy
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data
from rclpy.time import Time
from rclpy.duration import Duration

class VRServer(Node):
  SDF_PUBLISH_PD = 10.0
  MAX_AGE = Duration(seconds=30.0)

  def __init__(self):
    super().__init__('l2_vr')
    T0 = Time(clock_type=self.get_clock().clock_type)
    self.ignore_names = set(['ground_plane'])
    self.sim_model_states = ModelStates()
    self.last_sim_msg = T0
    self.vr_object3d = Object3DArray()
    self.last_vr_msg = T0
    self.get_logger().info("Init")
    self.create_subscription(Object3DArray, "/l2/vr/Object3D", self.set_vr_state, qos_profile_sensor_data)
    self.create_subscription(ModelStates, "/model_states", self.set_sim_state, qos_profile_sensor_data)
    self.create_timer(10.0, self.log_status)
    self.create_timer(5.0, self.resolve_diffs)
    self.getcli = node.create_client(GetObject3D, '/get_object3d')
    self.spawncli = node.create_client(SpawnObject3D, '/spawn_object3d')

  def vr_missing(self):
    now = self.get_clock().now()
    if now - self.last_sim_msg > self.MAX_AGE:
      self.get_logger().info("Sim stale (not running?): %s" % self.last_sim_msg)
      return set()
    if now - self.last_vr_msg > self.MAX_AGE:
      self.get_logger().info("VR stale (not running?): %s" % self.last_vr_msg)
      return set()

    gz_objs = set(self.sim_model_states.name).difference(self.ignore_names)
    vr_objs = set([v.name for v in self.vr_object3d.objects])
    return gz_objs.difference(vr_objs)

  def resolve_diffs(self):
    # TODO handle possible overrun in diff resolution
    if not self.getcli.wait_for_service(timeout_sec=1.0):
      node.get_logger().info('GetObject3D service not available')
      return

    for name in self.vr_missing():
      req = GetObject3D.Request()
      req.name = name
      future = getcli.call_async(req)
      rclpy.spin_until_future_complete(node, future, timeout_sec=1.0)
      try:
        result = future.result()
      except Exception as e:
          node.get_logger().info('GetObject3D failed: %r' % (e,))
          continue
      else:
        if not result.success:
          node.get_logger().warn(str(result.message))
          continue

        node.get_logger().info(str(result))
        req = SpawnObject3D.Request()
        req.object = result.object
        req.object.name = name # Use registry name, not object real name
        req.scale = 1.0
        # req.pose = ???
        node.get_logger().info("Calling SpawnObject3D with object name %s" % req.object.name)
        future = spawncli.call_async(req)
        rclpy.spin_until_future_complete(node, future, timeout_sec=1.0)
        if !future.done():
          future.cancel()
        else:
          node.get_logger().info(str(future.result()))

  def log_status(self):
    status = {
      "sim_ts": self.last_sim_msg,
      "sim_objs": len(self.sim_model_states.name),
      "vr_ts": self.last_vr_msg,
      "vr_objs": len(self.vr_object3d.objects),
      "vr_missing": self.vr_missing(),
    }
    self.get_logger().info(pprint.pformat(status))

  def set_vr_state(self, msg):
    self.vr_object3d = msg
    self.last_vr_msg = self.get_clock().now()

  def set_sim_state(self, msg):
    self.sim_model_states = msg
    self.last_sim_msg = self.get_clock().now()

def main(args=None):
  rclpy.init(args=args)
  vr_server = VRServer()
  rclpy.spin(vr_server)
  rclpy.shutdown()

if __name__ == '__main__':
  main()