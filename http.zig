const std = @import("std");

// http client for lichess in zig
const BASE_URL: []const u8 = "https://lichess.org";
var token: [24]u8 = undefined;
var username: [24]u8 = undefined;

// refactor to abstract the http client return http body for the api call
pub fn make_request(method: std.http.Method, url: []const u8, params: []const u8) ![]u8 {
    const allocator = std.heap.page_allocator;
    var client = std.http.Client{ .allocator = allocator };
    // build url from base url
    defer client.deinit();
    var buffer: [256]u8 = undefined;
    const fullUrl = try std.fmt.bufPrint(&buffer, "{s}{s}{s}", .{ BASE_URL, url, params });
    const uri = std.Uri.parse(fullUrl) catch unreachable;
    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();
    try headers.append("Authorization", "Bearer " ++ token);
    try headers.append("Accept", "application/json");
    var request = try client.request(method, uri, headers, .{});
    defer request.deinit();
    try request.start();
    try request.wait();
    const body = request.reader().readAllAlloc(allocator, 1024 * 128) catch unreachable;
    return body;
}

// get online bots
pub fn get_online_bots() ![]u8 {
    return make_request(.GET, "/api/bot/online", "?nb=1");
}

// challenge user
pub fn challenge_user(user: []const u8) ![]u8 {
    var buffer: [256]u8 = undefined;
    const url = try std.fmt.bufPrint(&buffer, "{s}{s}", .{ "/api/challenge/", user });
    return make_request(.POST, url, .{});
}

pub fn main() !u8 {
    const tokenConst = std.os.getenv("LICHESS_TOKEN") orelse {
        std.debug.print("LICHESS_TOKEN environment variable not found.\n", .{});
        return 1; // Return non-zero status to indicate an error
    };
    const usernameConst = std.os.getenv("LICHESS_USERNAME") orelse {
        std.debug.print("LICHESS_USERNAME environment variable not found.\n", .{});
        return 1; // Return non-zero status to indicate an error
    };
    std.mem.copy(u8, &token, tokenConst);
    std.mem.copy(u8, &username, usernameConst);
    const online_bots = try get_online_bots();
    std.debug.print("online bots: {s}\n", .{online_bots});
    //const challenge = try challenge_user("username");
    //std.debug.print("challenge: {s}\n", .{challenge});

    return 0;
}
