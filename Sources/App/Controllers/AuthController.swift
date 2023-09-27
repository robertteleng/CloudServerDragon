import Vapor

struct AuthController: RouteCollection {
    // MARK: - Override
    func boot(routes: Vapor.RoutesBuilder) throws {

        routes.group("auth") { builder in

            builder.post("signup", use: signUp)
        }
    }
  
    // MARK: - Routes
    func signUp(req: Request) async throws -> JWTToken.Public {

        //Validate
        try User.Create.validate(content: req)
        
        // Decode user data
        var userCreate = try req.content.decode(User.Create.self)
        userCreate.password = try req.password.hash(userCreate.password)

        // Save user to db
        let user = User(name: userCreate.name, email: userCreate.email, password: userCreate.password)
        try await user.create(on: req.db)
        
        // JWT Tokens
        // Create tokens
        let tokens = JWTToken.generateTokens(userID: user.id!)
        print(tokens)
        // Sigend tokens
        let accessSigned = try req.jwt.sign(tokens.access)
        let refreshSigned = try req.jwt.sign(tokens.refresh)

        return JWTToken.Public(accesToken: accessSigned, refreshToken: refreshSigned)
    }
}
